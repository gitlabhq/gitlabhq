import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssueTypeField, { i18n } from '~/issue_show/components/fields/type.vue';
import { IssuableTypes } from '~/issue_show/constants';
import {
  getIssueStateQueryResponse,
  updateIssueStateQueryResponse,
} from '../../mock_data/apollo_mock';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Issue type field component', () => {
  let wrapper;
  let fakeApollo;
  let mockIssueStateData;

  const mockResolvers = {
    Query: {
      issueState() {
        return {
          __typename: 'IssueState',
          rawData: mockIssueStateData(),
        };
      },
    },
    Mutation: {
      updateIssueState: jest.fn().mockResolvedValue(updateIssueStateQueryResponse),
    },
  };

  const findTypeFromGroup = () => wrapper.findComponent(GlFormGroup);
  const findTypeFromDropDown = () => wrapper.findComponent(GlDropdown);
  const findTypeFromDropDownItems = () => wrapper.findAllComponents(GlDropdownItem);

  const createComponent = ({ data } = {}) => {
    fakeApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMount(IssueTypeField, {
      localVue,
      apolloProvider: fakeApollo,
      data() {
        return {
          issueState: {},
          ...data,
        };
      },
    });
  };

  beforeEach(() => {
    mockIssueStateData = jest.fn();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a form group with the correct label', () => {
    expect(findTypeFromGroup().attributes('label')).toBe(i18n.label);
  });

  it('renders a form select with the `issue_type` value', () => {
    expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.issue);
  });

  describe('with Apollo cache mock', () => {
    it('renders the selected issueType', async () => {
      mockIssueStateData.mockResolvedValue(getIssueStateQueryResponse);
      await waitForPromises();
      expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.issue);
    });

    it('updates the `issue_type` in the apollo cache when the value is changed', async () => {
      findTypeFromDropDownItems().at(1).vm.$emit('click', IssuableTypes.incident);
      await wrapper.vm.$nextTick();
      expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.incident);
    });
  });
});
