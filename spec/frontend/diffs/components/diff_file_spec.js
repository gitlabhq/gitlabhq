import Vue from 'vue';
import { createStore } from '~/mr_notes/stores';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import DiffFileComponent from '~/diffs/components/diff_file.vue';
import { diffViewerModes, diffViewerErrors } from '~/ide/constants';
import diffFileMockDataReadable from '../mock_data/diff_file';
import diffFileMockDataUnreadable from '../mock_data/diff_file_unreadable';

describe('DiffFile', () => {
  let vm;
  let trackingSpy;

  beforeEach(() => {
    vm = createComponentWithStore(Vue.extend(DiffFileComponent), createStore(), {
      file: JSON.parse(JSON.stringify(diffFileMockDataReadable)),
      canCurrentUserFork: false,
    }).$mount();
    trackingSpy = mockTracking('_category_', vm.$el, jest.spyOn);
  });

  afterEach(() => {
    vm.$destroy();
  });

  const findDiffContent = () => vm.$el.querySelector('.diff-content');
  const isVisible = el => el.style.display !== 'none';

  describe('template', () => {
    it('should render component with file header, file content components', done => {
      const el = vm.$el;
      const { file_hash, file_path } = vm.file;

      expect(el.id).toEqual(file_hash);
      expect(el.classList.contains('diff-file')).toEqual(true);

      expect(el.querySelectorAll('.diff-content.hidden').length).toEqual(0);
      expect(el.querySelector('.js-file-title')).toBeDefined();
      expect(el.querySelector('.btn-clipboard')).toBeDefined();
      expect(el.querySelector('.file-title-name').innerText.indexOf(file_path)).toBeGreaterThan(-1);
      expect(el.querySelector('.js-syntax-highlight')).toBeDefined();

      vm.file.renderIt = true;

      vm.$nextTick()
        .then(() => {
          expect(el.querySelectorAll('.line_content').length).toBe(5);
          expect(el.querySelectorAll('.js-line-expansion-content').length).toBe(1);
          triggerEvent('.btn-clipboard');
        })
        .then(done)
        .catch(done.fail);
    });

    it('should track a click event on copy to clip board button', done => {
      const el = vm.$el;

      expect(el.querySelector('.btn-clipboard')).toBeDefined();
      vm.file.renderIt = true;
      vm.$nextTick()
        .then(() => {
          triggerEvent('.btn-clipboard');

          expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_copy_file_button', {
            label: 'diff_copy_file_path_button',
            property: 'diff_copy_file',
          });
        })
        .then(done)
        .catch(done.fail);
    });

    describe('collapsed', () => {
      it('should not have file content', done => {
        expect(isVisible(findDiffContent())).toBe(true);
        expect(vm.isCollapsed).toEqual(false);
        vm.isCollapsed = true;
        vm.file.renderIt = true;

        vm.$nextTick(() => {
          expect(isVisible(findDiffContent())).toBe(false);

          done();
        });
      });

      it('should have collapsed text and link', done => {
        vm.renderIt = true;
        vm.isCollapsed = true;

        vm.$nextTick(() => {
          expect(vm.$el.innerText).toContain('This diff is collapsed');
          expect(vm.$el.querySelectorAll('.js-click-to-expand').length).toEqual(1);

          done();
        });
      });

      it('should have collapsed text and link even before rendered', done => {
        vm.renderIt = false;
        vm.isCollapsed = true;

        vm.$nextTick(() => {
          expect(vm.$el.innerText).toContain('This diff is collapsed');
          expect(vm.$el.querySelectorAll('.js-click-to-expand').length).toEqual(1);

          done();
        });
      });

      it('should be collapsable for unreadable files', done => {
        vm.$destroy();
        vm = createComponentWithStore(Vue.extend(DiffFileComponent), createStore(), {
          file: JSON.parse(JSON.stringify(diffFileMockDataUnreadable)),
          canCurrentUserFork: false,
        }).$mount();

        vm.renderIt = false;
        vm.isCollapsed = true;

        vm.$nextTick(() => {
          expect(vm.$el.innerText).toContain('This diff is collapsed');
          expect(vm.$el.querySelectorAll('.js-click-to-expand').length).toEqual(1);

          done();
        });
      });

      it('should be collapsed for renamed files', done => {
        vm.renderIt = true;
        vm.isCollapsed = false;
        vm.file.highlighted_diff_lines = null;
        vm.file.viewer.name = diffViewerModes.renamed;

        vm.$nextTick(() => {
          expect(vm.$el.innerText).not.toContain('This diff is collapsed');

          done();
        });
      });

      it('should be collapsed for mode changed files', done => {
        vm.renderIt = true;
        vm.isCollapsed = false;
        vm.file.highlighted_diff_lines = null;
        vm.file.viewer.name = diffViewerModes.mode_changed;

        vm.$nextTick(() => {
          expect(vm.$el.innerText).not.toContain('This diff is collapsed');

          done();
        });
      });

      it('should have loading icon while loading a collapsed diffs', done => {
        vm.isCollapsed = true;
        vm.isLoadingCollapsedDiff = true;

        vm.$nextTick(() => {
          expect(vm.$el.querySelectorAll('.diff-content.loading').length).toEqual(1);

          done();
        });
      });

      it('should update store state', done => {
        jest.spyOn(vm.$store, 'dispatch').mockImplementation(() => {});

        vm.isCollapsed = true;

        vm.$nextTick(() => {
          expect(vm.$store.dispatch).toHaveBeenCalledWith('diffs/setFileCollapsed', {
            filePath: vm.file.file_path,
            collapsed: true,
          });

          done();
        });
      });

      it('updates local state when changing file state', done => {
        vm.file.viewer.collapsed = true;

        vm.$nextTick(() => {
          expect(vm.isCollapsed).toBe(true);

          done();
        });
      });
    });
  });

  describe('too large diff', () => {
    it('should have too large warning and blob link', done => {
      const BLOB_LINK = '/file/view/path';
      vm.file.viewer.error = diffViewerErrors.too_large;
      vm.file.viewer.error_message =
        'This source diff could not be displayed because it is too large';
      vm.file.view_path = BLOB_LINK;
      vm.file.renderIt = true;

      vm.$nextTick(() => {
        expect(vm.$el.innerText).toContain(
          'This source diff could not be displayed because it is too large',
        );

        done();
      });
    });
  });

  describe('watch collapsed', () => {
    it('calls handleLoadCollapsedDiff if collapsed changed & file has no lines', done => {
      jest.spyOn(vm, 'handleLoadCollapsedDiff').mockImplementation(() => {});

      vm.file.highlighted_diff_lines = undefined;
      vm.file.parallel_diff_lines = [];
      vm.isCollapsed = true;

      vm.$nextTick()
        .then(() => {
          vm.isCollapsed = false;

          return vm.$nextTick();
        })
        .then(() => {
          expect(vm.handleLoadCollapsedDiff).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not call handleLoadCollapsedDiff if collapsed changed & file is unreadable', done => {
      vm.$destroy();
      vm = createComponentWithStore(Vue.extend(DiffFileComponent), createStore(), {
        file: JSON.parse(JSON.stringify(diffFileMockDataUnreadable)),
        canCurrentUserFork: false,
      }).$mount();

      jest.spyOn(vm, 'handleLoadCollapsedDiff').mockImplementation(() => {});

      vm.file.highlighted_diff_lines = undefined;
      vm.file.parallel_diff_lines = [];
      vm.isCollapsed = true;

      vm.$nextTick()
        .then(() => {
          vm.isCollapsed = false;

          return vm.$nextTick();
        })
        .then(() => {
          expect(vm.handleLoadCollapsedDiff).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
