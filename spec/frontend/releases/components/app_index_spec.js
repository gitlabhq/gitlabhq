import { range as rge } from 'lodash';
import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import ReleasesApp from '~/releases/components/app_index.vue';
import createStore from '~/releases/stores';
import listModule from '~/releases/stores/modules/list';
import api from '~/api';
import {
  pageInfoHeadersWithoutPagination,
  pageInfoHeadersWithPagination,
  release2 as release,
  releases,
} from '../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Releases App ', () => {
  let wrapper;

  const releasesPagination = rge(21).map(index => ({
    ...convertObjectPropsToCamelCase(release, { deep: true }),
    tagName: `${index}.00`,
  }));

  const defaultProps = {
    projectId: 'gitlab-ce',
    documentationPath: 'help/releases',
    illustrationPath: 'illustration/path',
  };

  const createComponent = (propsData = defaultProps) => {
    const store = createStore({ modules: { list: listModule } });

    wrapper = shallowMount(ReleasesApp, {
      store,
      localVue,
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      jest
        .spyOn(api, 'releases')
        // Need to defer the return value here to the next stack,
        // otherwise the loading state disappears before our test even starts.
        .mockImplementation(() => waitForPromises().then(() => ({ data: [], headers: {} })));

      createComponent();
    });

    it('renders loading icon', () => {
      expect(wrapper.contains('.js-loading')).toBe(true);
      expect(wrapper.contains('.js-empty-state')).toBe(false);
      expect(wrapper.contains('.js-success-state')).toBe(false);
      expect(wrapper.contains(TablePagination)).toBe(false);
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      jest
        .spyOn(api, 'releases')
        .mockResolvedValue({ data: releases, headers: pageInfoHeadersWithoutPagination });

      createComponent();
    });

    it('renders success state', () => {
      expect(wrapper.contains('.js-loading')).toBe(false);
      expect(wrapper.contains('.js-empty-state')).toBe(false);
      expect(wrapper.contains('.js-success-state')).toBe(true);
      expect(wrapper.contains(TablePagination)).toBe(true);
    });
  });

  describe('with successful request and pagination', () => {
    beforeEach(() => {
      jest
        .spyOn(api, 'releases')
        .mockResolvedValue({ data: releasesPagination, headers: pageInfoHeadersWithPagination });

      createComponent();
    });

    it('renders success state', () => {
      expect(wrapper.contains('.js-loading')).toBe(false);
      expect(wrapper.contains('.js-empty-state')).toBe(false);
      expect(wrapper.contains('.js-success-state')).toBe(true);
      expect(wrapper.contains(TablePagination)).toBe(true);
    });
  });

  describe('with empty request', () => {
    beforeEach(() => {
      jest.spyOn(api, 'releases').mockResolvedValue({ data: [], headers: {} });

      createComponent();
    });

    it('renders empty state', () => {
      expect(wrapper.contains('.js-loading')).toBe(false);
      expect(wrapper.contains('.js-empty-state')).toBe(true);
      expect(wrapper.contains('.js-success-state')).toBe(false);
    });
  });

  describe('"New release" button', () => {
    const findNewReleaseButton = () => wrapper.find('.js-new-release-btn');

    beforeEach(() => {
      jest.spyOn(api, 'releases').mockResolvedValue({ data: [], headers: {} });
    });

    describe('when the user is allowed to create a new Release', () => {
      const newReleasePath = 'path/to/new/release';

      beforeEach(() => {
        createComponent({ ...defaultProps, newReleasePath });
      });

      it('renders the "New release" button', () => {
        expect(findNewReleaseButton().exists()).toBe(true);
      });

      it('renders the "New release" button with the correct href', () => {
        expect(findNewReleaseButton().attributes('href')).toBe(newReleasePath);
      });
    });

    describe('when the user is not allowed to create a new Release', () => {
      beforeEach(() => createComponent());

      it('does not render the "New release" button', () => {
        expect(findNewReleaseButton().exists()).toBe(false);
      });
    });
  });
});
