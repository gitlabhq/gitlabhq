import { GlAlert, GlFormInput, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { workspaceLabelsQueries, workspaceCreateLabelMutation } from '~/sidebar/queries/constants';
import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue';
import SidebarColorPicker from '~/sidebar/components/sidebar_color_picker.vue';
import { DEFAULT_LABEL_COLOR } from '~/sidebar/components/labels/labels_select_widget/constants';
import {
  mockCreateLabelResponse as createAbuseReportLabelSuccessfulResponse,
  mockLabelsQueryResponse as abuseReportLabelsQueryResponse,
} from '../../../../admin/abuse_report/mock_data';
import { mockSuggestedColors } from '../../mock_data';
import {
  mockRegularLabel,
  createLabelSuccessfulResponse,
  workspaceLabelsQueryResponse,
  workspaceLabelsQueryEmptyResponse,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const userRecoverableError = {
  ...createLabelSuccessfulResponse,
  errors: ['Houston, we have a problem'],
};

const titleTakenError = {
  data: {
    labelCreate: {
      label: mockRegularLabel,
      errors: ['Title has already been taken'],
    },
  },
};

const createLabelSuccessHandler = jest.fn().mockResolvedValue(createLabelSuccessfulResponse);
const createAbuseReportLabelSuccessHandler = jest
  .fn()
  .mockResolvedValue(createAbuseReportLabelSuccessfulResponse);
const createLabelUserRecoverableErrorHandler = jest.fn().mockResolvedValue(userRecoverableError);
const createLabelDuplicateErrorHandler = jest.fn().mockResolvedValue(titleTakenError);
const createLabelErrorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

describe('DropdownContentsCreateView', () => {
  let wrapper;

  const findSidebarColorPicker = () => wrapper.findComponent(SidebarColorPicker);
  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findLabelTitleInput = () => wrapper.findComponent(GlFormInput);

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const fillLabelAttributes = () => {
    findLabelTitleInput().vm.$emit('input', 'Test title');
    findSidebarColorPicker().vm.$emit('input', '#009966');
  };

  const createComponent = ({
    mutationHandler = createLabelSuccessHandler,
    labelCreateType = 'project',
    workspaceType = 'project',
    labelsResponse = workspaceLabelsQueryResponse,
    searchTerm = '',
  } = {}) => {
    const createLabelMutation = workspaceCreateLabelMutation[workspaceType];
    const mockApollo = createMockApollo([[createLabelMutation, mutationHandler]]);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: workspaceLabelsQueries[workspaceType].query,
      data: labelsResponse.data,
      variables: {
        fullPath: '',
        searchTerm,
      },
    });

    wrapper = shallowMount(DropdownContentsCreateView, {
      apolloProvider: mockApollo,
      propsData: {
        fullPath: '',
        attrWorkspacePath: '',
        labelCreateType,
        workspaceType,
      },
    });
  };

  beforeEach(() => {
    gon.suggested_label_colors = mockSuggestedColors;
  });

  it('disables a Create button if label title is not set', async () => {
    createComponent();
    findSidebarColorPicker().vm.$emit('input', '#fff');
    await nextTick();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('disables a Create button if color is not set', async () => {
    createComponent();
    findLabelTitleInput().vm.$emit('input', 'Test title');
    findSidebarColorPicker().vm.$emit('input', '');
    await nextTick();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('does not render a loader spinner', () => {
    createComponent();
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('emits a `hideCreateView` event on Cancel button click', () => {
    createComponent();
    const event = { stopPropagation: jest.fn() };
    findCancelButton().vm.$emit('click', event);

    expect(wrapper.emitted('hideCreateView')).toHaveLength(1);
    expect(event.stopPropagation).toHaveBeenCalled();
  });

  describe('when label title and selected color are set', () => {
    beforeEach(() => {
      createComponent();
      fillLabelAttributes();
    });

    it('enables a Create button', () => {
      expect(findCreateButton().props()).toMatchObject({
        disabled: false,
        category: 'primary',
        variant: 'confirm',
      });
    });

    it('renders a loader spinner after Create button click', async () => {
      findCreateButton().vm.$emit('click');
      await nextTick();

      expect(findCreateButton().props('loading')).toBe(true);
    });

    it('does not loader spinner after mutation is resolved', async () => {
      findCreateButton().vm.$emit('click');
      await nextTick();

      expect(findCreateButton().props('loading')).toBe(true);
      await waitForPromises();

      expect(findCreateButton().props('loading')).toBe(false);
    });
  });

  it('calls a mutation with `projectPath` variable on the issue', () => {
    createComponent();
    fillLabelAttributes();
    findCreateButton().vm.$emit('click');

    expect(createLabelSuccessHandler).toHaveBeenCalledWith({
      color: '#009966',
      projectPath: '',
      title: 'Test title',
    });
  });

  it('calls a mutation with `groupPath` variable on the epic', () => {
    createComponent({ labelCreateType: 'group', workspaceType: 'group' });
    fillLabelAttributes();
    findCreateButton().vm.$emit('click');

    expect(createLabelSuccessHandler).toHaveBeenCalledWith({
      color: '#009966',
      groupPath: '',
      title: 'Test title',
    });
  });

  it('calls the correct mutation when workspaceType is `abuseReport`', () => {
    createComponent({
      mutationHandler: createAbuseReportLabelSuccessHandler,
      labelCreateType: '',
      workspaceType: 'abuseReport',
      labelsResponse: abuseReportLabelsQueryResponse,
    });
    fillLabelAttributes();
    findCreateButton().vm.$emit('click');

    expect(createAbuseReportLabelSuccessHandler).toHaveBeenCalledWith({
      color: '#009966',
      title: 'Test title',
    });
  });

  it('calls createAlert is mutation has a user-recoverable error', async () => {
    createComponent({ mutationHandler: createLabelUserRecoverableErrorHandler });
    fillLabelAttributes();
    await nextTick();

    findCreateButton().vm.$emit('click');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  it('calls createAlert is mutation was rejected', async () => {
    createComponent({ mutationHandler: createLabelErrorHandler });
    fillLabelAttributes();
    await nextTick();

    findCreateButton().vm.$emit('click');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  it('displays error in alert if label title is already taken', async () => {
    createComponent({ mutationHandler: createLabelDuplicateErrorHandler });
    fillLabelAttributes();
    await nextTick();

    findCreateButton().vm.$emit('click');
    await waitForPromises();

    expect(wrapper.findComponent(GlAlert).text()).toEqual(
      titleTakenError.data.labelCreate.errors[0],
    );
  });

  describe('when empty labels response', () => {
    it('is able to create label with searched text when empty response', async () => {
      createComponent({ searchTerm: '', labelsResponse: workspaceLabelsQueryEmptyResponse });

      findLabelTitleInput().vm.$emit('input', 'random');

      findCreateButton().vm.$emit('click');
      await waitForPromises();

      expect(createLabelSuccessHandler).toHaveBeenCalledWith({
        color: DEFAULT_LABEL_COLOR,
        projectPath: '',
        title: 'random',
      });
    });
  });
});
