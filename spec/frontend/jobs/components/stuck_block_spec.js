import Vue from 'vue';
import component from '~/jobs/components/stuck_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Stuck Block Job component', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with no runners for project', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        hasNoRunnersForProject: true,
        runnersPath: '/root/project/runners#js-runners-settings',
      });
    });

    it('renders only information about project not having runners', () => {
      expect(vm.$el.querySelector('.js-stuck-no-runners')).not.toBeNull();
      expect(vm.$el.querySelector('.js-stuck-with-tags')).toBeNull();
      expect(vm.$el.querySelector('.js-stuck-no-active-runner')).toBeNull();
    });

    it('renders link to runners page', () => {
      expect(vm.$el.querySelector('.js-runners-path').getAttribute('href')).toEqual(
        '/root/project/runners#js-runners-settings',
      );
    });
  });

  describe('with tags', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        hasNoRunnersForProject: false,
        tags: ['docker', 'gitlab-org'],
        runnersPath: '/root/project/runners#js-runners-settings',
      });
    });

    it('renders information about the tags not being set', () => {
      expect(vm.$el.querySelector('.js-stuck-no-runners')).toBeNull();
      expect(vm.$el.querySelector('.js-stuck-with-tags')).not.toBeNull();
      expect(vm.$el.querySelector('.js-stuck-no-active-runner')).toBeNull();
    });

    it('renders tags', () => {
      expect(vm.$el.textContent).toContain('docker');
      expect(vm.$el.textContent).toContain('gitlab-org');
    });

    it('renders link to runners page', () => {
      expect(vm.$el.querySelector('.js-runners-path').getAttribute('href')).toEqual(
        '/root/project/runners#js-runners-settings',
      );
    });
  });

  describe('without active runners', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        hasNoRunnersForProject: false,
        runnersPath: '/root/project/runners#js-runners-settings',
      });
    });

    it('renders information about project not having runners', () => {
      expect(vm.$el.querySelector('.js-stuck-no-runners')).toBeNull();
      expect(vm.$el.querySelector('.js-stuck-with-tags')).toBeNull();
      expect(vm.$el.querySelector('.js-stuck-no-active-runner')).not.toBeNull();
    });

    it('renders link to runners page', () => {
      expect(vm.$el.querySelector('.js-runners-path').getAttribute('href')).toEqual(
        '/root/project/runners#js-runners-settings',
      );
    });
  });
});
