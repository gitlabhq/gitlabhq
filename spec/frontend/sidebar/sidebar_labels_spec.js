import { createLocalVue, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import {
  mockLabels,
  mockRegularLabel,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';
import axios from '~/lib/utils/axios_utils';
import SidebarLabels from '~/sidebar/components/labels/sidebar_labels.vue';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import labelsSelectModule from '~/vue_shared/components/sidebar/labels_select_vue/store';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('sidebar labels', () => {
  let axiosMock;
  let wrapper;

  const store = new Vuex.Store(labelsSelectModule());

  const defaultProps = {
    allowLabelCreate: true,
    allowLabelEdit: true,
    allowScopedLabels: true,
    canEdit: true,
    iid: '1',
    initiallySelectedLabels: mockLabels,
    issuableType: 'issue',
    labelsFetchPath: '/gitlab-org/gitlab-test/-/labels.json?include_ancestor_groups=true',
    labelsManagePath: '/gitlab-org/gitlab-test/-/labels',
    labelsUpdatePath: '/gitlab-org/gitlab-test/-/issues/1.json',
    projectIssuesPath: '/gitlab-org/gitlab-test/-/issues',
    projectPath: 'gitlab-org/gitlab-test',
  };

  const findLabelsSelect = () => wrapper.find(LabelsSelect);

  const mountComponent = () => {
    wrapper = shallowMount(SidebarLabels, {
      localVue,
      provide: {
        ...defaultProps,
      },
      store,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    axiosMock.restore();
  });

  describe('LabelsSelect props', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('are as expected', () => {
      expect(findLabelsSelect().props()).toMatchObject({
        allowLabelCreate: defaultProps.allowLabelCreate,
        allowLabelEdit: defaultProps.allowLabelEdit,
        allowMultiselect: true,
        allowScopedLabels: defaultProps.allowScopedLabels,
        footerCreateLabelTitle: 'Create project label',
        footerManageLabelTitle: 'Manage project labels',
        labelsCreateTitle: 'Create project label',
        labelsFetchPath: defaultProps.labelsFetchPath,
        labelsFilterBasePath: defaultProps.projectIssuesPath,
        labelsManagePath: defaultProps.labelsManagePath,
        labelsSelectInProgress: false,
        selectedLabels: defaultProps.initiallySelectedLabels,
        variant: DropdownVariant.Sidebar,
      });
    });
  });

  describe('when labels are changed', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('makes an API call to update labels', async () => {
      const labels = [
        {
          ...mockRegularLabel,
          set: false,
        },
        {
          id: 40,
          title: 'Security',
          color: '#ddd',
          text_color: '#fff',
          set: true,
        },
        {
          id: 55,
          title: 'Tooling',
          color: '#ddd',
          text_color: '#fff',
          set: false,
        },
      ];

      findLabelsSelect().vm.$emit('updateSelectedLabels', labels);

      await axios.waitForAll();

      const expected = {
        [defaultProps.issuableType]: {
          label_ids: [27, 28, 40],
        },
      };

      expect(axiosMock.history.put[0].data).toEqual(JSON.stringify(expected));
    });
  });
});
