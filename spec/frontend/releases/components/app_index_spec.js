import { range as rge } from 'lodash';
import Vue from 'vue';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import app from '~/releases/components/app_index.vue';
import createStore from '~/releases/stores';
import listModule from '~/releases/stores/modules/list';
import api from '~/api';
import { resetStore } from '../stores/modules/list/helpers';
import {
  pageInfoHeadersWithoutPagination,
  pageInfoHeadersWithPagination,
  release2 as release,
  releases,
} from '../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import waitForPromises from 'helpers/wait_for_promises';

describe('Releases App ', () => {
  const Component = Vue.extend(app);
  let store;
  let vm;
  let releasesPagination;

  const props = {
    projectId: 'gitlab-ce',
    documentationPath: 'help/releases',
    illustrationPath: 'illustration/path',
  };

  beforeEach(() => {
    store = createStore({ modules: { list: listModule } });
    releasesPagination = rge(21).map(index => ({
      ...convertObjectPropsToCamelCase(release, { deep: true }),
      tagName: `${index}.00`,
    }));
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      jest
        .spyOn(api, 'releases')
        // Need to defer the return value here to the next stack,
        // otherwise the loading state disappears before our test even starts.
        .mockImplementation(() => waitForPromises().then(() => ({ data: [], headers: {} })));
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders loading icon', () => {
      expect(vm.$el.querySelector('.js-loading')).not.toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).toBeNull();
      expect(vm.$el.querySelector('.gl-pagination')).toBeNull();

      return waitForPromises();
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      jest
        .spyOn(api, 'releases')
        .mockResolvedValue({ data: releases, headers: pageInfoHeadersWithoutPagination });
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders success state', () => {
      expect(vm.$el.querySelector('.js-loading')).toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).not.toBeNull();
      expect(vm.$el.querySelector('.gl-pagination')).toBeNull();
    });
  });

  describe('with successful request and pagination', () => {
    beforeEach(() => {
      jest
        .spyOn(api, 'releases')
        .mockResolvedValue({ data: releasesPagination, headers: pageInfoHeadersWithPagination });
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders success state', () => {
      expect(vm.$el.querySelector('.js-loading')).toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).not.toBeNull();
      expect(vm.$el.querySelector('.gl-pagination')).not.toBeNull();
    });
  });

  describe('with empty request', () => {
    beforeEach(() => {
      jest.spyOn(api, 'releases').mockResolvedValue({ data: [], headers: {} });
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders empty state', () => {
      expect(vm.$el.querySelector('.js-loading')).toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).not.toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).toBeNull();
      expect(vm.$el.querySelector('.gl-pagination')).toBeNull();
    });
  });

  describe('"New release" button', () => {
    const findNewReleaseButton = () => vm.$el.querySelector('.js-new-release-btn');

    beforeEach(() => {
      jest.spyOn(api, 'releases').mockResolvedValue({ data: [], headers: {} });
    });

    const factory = additionalProps => {
      vm = mountComponentWithStore(Component, {
        props: {
          ...props,
          ...additionalProps,
        },
        store,
      });
    };

    describe('when the user is allowed to create a new Release', () => {
      const newReleasePath = 'path/to/new/release';

      beforeEach(() => {
        factory({ newReleasePath });
      });

      it('renders the "New release" button', () => {
        expect(findNewReleaseButton()).not.toBeNull();
      });

      it('renders the "New release" button with the correct href', () => {
        expect(findNewReleaseButton().getAttribute('href')).toBe(newReleasePath);
      });
    });

    describe('when the user is not allowed to create a new Release', () => {
      beforeEach(() => factory());

      it('does not render the "New release" button', () => {
        expect(findNewReleaseButton()).toBeNull();
      });
    });
  });
});
