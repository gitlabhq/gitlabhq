import Vue from 'vue';
import component from '~/jobs/components/commit_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Commit block', () => {
  const Component = Vue.extend(component);
  let vm;

  const props = {
    commit: {
      short_id: '1f0fb84f',
      id: '1f0fb84fb6770d74d97eee58118fd3909cd4f48c',
      commit_path: 'commit/1f0fb84fb6770d74d97eee58118fd3909cd4f48c',
      title: 'Update README.md',
    },
    mergeRequest: {
      iid: '!21244',
      path: 'merge_requests/21244',
    },
    isLastBlock: true,
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('pipeline short sha', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...props,
      });
    });

    it('renders pipeline short sha link', () => {
      expect(vm.$el.querySelector('.js-commit-sha').getAttribute('href')).toEqual(
        props.commit.commit_path,
      );

      expect(vm.$el.querySelector('.js-commit-sha').textContent.trim()).toEqual(
        props.commit.short_id,
      );
    });

    it('renders clipboard button', () => {
      expect(vm.$el.querySelector('button').getAttribute('data-clipboard-text')).toEqual(
        props.commit.id,
      );
    });
  });

  describe('with merge request', () => {
    it('renders merge request link and reference', () => {
      vm = mountComponent(Component, {
        ...props,
      });

      expect(vm.$el.querySelector('.js-link-commit').getAttribute('href')).toEqual(
        props.mergeRequest.path,
      );

      expect(vm.$el.querySelector('.js-link-commit').textContent.trim()).toEqual(
        `!${props.mergeRequest.iid}`,
      );
    });
  });

  describe('without merge request', () => {
    it('does not render merge request', () => {
      const copyProps = { ...props };
      delete copyProps.mergeRequest;

      vm = mountComponent(Component, {
        ...copyProps,
      });

      expect(vm.$el.querySelector('.js-link-commit')).toBeNull();
    });
  });

  describe('git commit title', () => {
    it('renders git commit title', () => {
      vm = mountComponent(Component, {
        ...props,
      });

      expect(vm.$el.textContent).toContain(props.commit.title);
    });
  });
});
