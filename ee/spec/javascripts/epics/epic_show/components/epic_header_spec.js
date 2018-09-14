import Vue from 'vue';
import epicHeader from 'ee/epics/epic_show/components/epic_header.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { headerProps } from '../mock_data';

describe('epicHeader', () => {
  let vm;
  const { author } = headerProps;

  beforeEach(() => {
    const EpicHeader = Vue.extend(epicHeader);
    vm = mountComponent(EpicHeader, headerProps);
  });

  it('should render timeago tooltip', () => {
    expect(vm.$el.querySelector('time')).toBeDefined();
  });

  it('should link to author url', () => {
    expect(vm.$el.querySelector('a').href).toEqual(author.url);
  });

  it('should render author avatar', () => {
    expect(vm.$el.querySelector('img').src).toEqual(`${author.src}?width=24`);
  });

  it('should render author name', () => {
    expect(vm.$el.querySelector('.user-avatar-link').innerText.trim()).toEqual(author.name);
  });

  it('should render username tooltip', () => {
    expect(vm.$el.querySelector('.user-avatar-link span').dataset.originalTitle).toEqual(
      author.username,
    );
  });

  it('should render sidebar toggle button', () => {
    expect(vm.$el.querySelector('button.js-sidebar-toggle')).not.toBe(null);
  });

  describe('canDelete', () => {
    it('should not show loading button by default', () => {
      expect(vm.$el.querySelector('.btn-remove')).toBeNull();
    });

    it('should show loading button if canDelete', done => {
      vm.canDelete = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.btn-remove')).toBeDefined();
        done();
      });
    });
  });

  describe('delete epic', () => {
    let deleteEpic;

    beforeEach(done => {
      deleteEpic = jasmine.createSpy();
      spyOn(window, 'confirm').and.returnValue(true);
      vm.canDelete = true;
      vm.$on('deleteEpic', deleteEpic);

      Vue.nextTick(() => {
        vm.$el.querySelector('.btn-remove').click();
        done();
      });
    });

    it('should set deleteLoading', () => {
      expect(vm.deleteLoading).toEqual(true);
    });

    it('should emit deleteEpic event', () => {
      expect(deleteEpic).toHaveBeenCalled();
    });
  });
});
