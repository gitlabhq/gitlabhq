import Vue from 'vue';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

describe('Batch comments publish dropdown component', () => {
  let vm;
  let Component;

  function createComponent(extendStore = () => {}) {
    const store = createStore();
    store.state.batchComments.drafts.push(createDraft(), { ...createDraft(), id: 2 });

    extendStore(store);

    vm = mountComponentWithStore(Component, { store });
  }

  beforeAll(() => {
    Component = Vue.extend(PreviewDropdown);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('toggles dropdown when clicking button', done => {
    createComponent();

    jest.spyOn(vm.$store, 'dispatch');

    vm.$el.querySelector('.review-preview-dropdown-toggle').click();

    expect(vm.$store.dispatch).toHaveBeenCalledWith(
      'batchComments/toggleReviewDropdown',
      expect.anything(),
    );

    setImmediate(() => {
      expect(vm.$el.classList).toContain('show');

      done();
    });
  });

  it('toggles dropdown when clicking body', () => {
    createComponent();

    vm.$store.state.batchComments.showPreviewDropdown = true;

    jest.spyOn(vm.$store, 'dispatch').mockImplementation();

    document.body.click();

    expect(vm.$store.dispatch).toHaveBeenCalledWith(
      'batchComments/toggleReviewDropdown',
      undefined,
    );
  });

  it('renders list of drafts', () => {
    createComponent(store => {
      Object.assign(store.state.notes, {
        isNotesFetched: true,
      });
    });

    expect(vm.$el.querySelectorAll('.dropdown-content li').length).toBe(2);
  });

  it('adds is-last class to last item', () => {
    createComponent(store => {
      Object.assign(store.state.notes, {
        isNotesFetched: true,
      });
    });

    expect(vm.$el.querySelectorAll('.dropdown-content li')[1].querySelector('.is-last')).not.toBe(
      null,
    );
  });

  it('renders draft count in dropdown title', () => {
    createComponent();

    expect(vm.$el.querySelector('.dropdown-title').textContent).toContain('2 pending comments');
  });

  it('renders publish button in footer', () => {
    createComponent();

    expect(vm.$el.querySelector('.dropdown-footer .js-publish-draft-button')).not.toBe(null);
  });
});
