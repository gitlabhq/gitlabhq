import VueApollo from 'vue-apollo';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert, GlSprintf } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeprecatedTypeKeywordNotification from '~/pipelines/components/notification/deprecated_type_keyword_notification.vue';
import getPipelineWarnings from '~/pipelines/graphql/queries/get_pipeline_warnings.query.graphql';
import {
  mockWarningsWithoutDeprecation,
  mockWarningsRootType,
  mockWarningsType,
  mockWarningsTypesAll,
} from './mock_data';

const defaultProvide = {
  deprecatedKeywordsDocPath: '/help/ci/yaml/index.md#deprecated-keywords',
  fullPath: '/namespace/my-project',
  pipelineIid: 4,
};

let wrapper;

const mockWarnings = jest.fn();

const createComponent = ({ isLoading = false, options = {} } = {}) => {
  return shallowMount(DeprecatedTypeKeywordNotification, {
    stubs: {
      GlSprintf,
    },
    provide: {
      ...defaultProvide,
    },
    mocks: {
      $apollo: {
        queries: {
          warnings: {
            loading: isLoading,
          },
        },
      },
    },
    ...options,
  });
};

const createComponentWithApollo = () => {
  const localVue = createLocalVue();
  localVue.use(VueApollo);

  const handlers = [[getPipelineWarnings, mockWarnings]];
  const mockApollo = createMockApollo(handlers);

  return createComponent({
    options: {
      localVue,
      apolloProvider: mockApollo,
      mocks: {},
    },
  });
};

const findAlert = () => wrapper.findComponent(GlAlert);
const findAlertItems = () => findAlert().findAll('li');

afterEach(() => {
  wrapper.destroy();
});

describe('Deprecated keyword notification', () => {
  describe('while loading the pipeline warnings', () => {
    beforeEach(() => {
      wrapper = createComponent({ isLoading: true });
    });

    it('does not display the notification', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('if there is an error in the query', () => {
    beforeEach(async () => {
      mockWarnings.mockResolvedValue({ errors: ['It didnt work'] });
      wrapper = createComponentWithApollo();
      await waitForPromises();
    });

    it('does not display the notification', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('with a valid query result', () => {
    describe('if there are no deprecation warnings', () => {
      beforeEach(async () => {
        mockWarnings.mockResolvedValue(mockWarningsWithoutDeprecation);
        wrapper = createComponentWithApollo();
        await waitForPromises();
      });
      it('does not show the notification', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('with a root type deprecation message', () => {
      beforeEach(async () => {
        mockWarnings.mockResolvedValue(mockWarningsRootType);
        wrapper = createComponentWithApollo();
        await waitForPromises();
      });
      it('shows the notification with one item', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlertItems()).toHaveLength(1);
        expect(findAlertItems().at(0).text()).toContain('types');
      });
    });

    describe('with a job type deprecation message', () => {
      beforeEach(async () => {
        mockWarnings.mockResolvedValue(mockWarningsType);
        wrapper = createComponentWithApollo();
        await waitForPromises();
      });
      it('shows the notification with one item', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlertItems()).toHaveLength(1);
        expect(findAlertItems().at(0).text()).toContain('type');
        expect(findAlertItems().at(0).text()).not.toContain('types');
      });
    });

    describe('with both the root types and job type deprecation message', () => {
      beforeEach(async () => {
        mockWarnings.mockResolvedValue(mockWarningsTypesAll);
        wrapper = createComponentWithApollo();
        await waitForPromises();
      });
      it('shows the notification with two items', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlertItems()).toHaveLength(2);
        expect(findAlertItems().at(0).text()).toContain('types');
        expect(findAlertItems().at(1).text()).toContain('type');
        expect(findAlertItems().at(1).text()).not.toContain('types');
      });
    });
  });
});
