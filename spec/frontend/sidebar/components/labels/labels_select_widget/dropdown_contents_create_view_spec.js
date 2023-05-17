import { GlAlert, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { workspaceLabelsQueries } from '~/sidebar/constants';
import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue';
import createLabelMutation from '~/sidebar/components/labels/labels_select_widget/graphql/create_label.mutation.graphql';
import { DEFAULT_LABEL_COLOR } from '~/sidebar/components/labels/labels_select_widget/constants';
import {
  mockRegularLabel,
  mockSuggestedColors,
  createLabelSuccessfulResponse,
  workspaceLabelsQueryResponse,
  workspaceLabelsQueryEmptyResponse,
} from './mock_data';

jest.mock('~/alert');

const colors = Object.keys(mockSuggestedColors);

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
const createLabelUserRecoverableErrorHandler = jest.fn().mockResolvedValue(userRecoverableError);
const createLabelDuplicateErrorHandler = jest.fn().mockResolvedValue(titleTakenError);
const createLabelErrorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

describe('DropdownContentsCreateView', () => {
  let wrapper;

  const findAllColors = () => wrapper.findAllComponents(GlLink);
  const findSelectedColor = () => wrapper.find('[data-testid="selected-color"]');
  const findSelectedColorText = () => wrapper.find('[data-testid="selected-color-text"]');
  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findLabelTitleInput = () => wrapper.find('[data-testid="label-title-input"]');

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const fillLabelAttributes = () => {
    findLabelTitleInput().vm.$emit('input', 'Test title');
    findAllColors().at(0).vm.$emit('click', new Event('mouseclick'));
  };

  const createComponent = ({
    mutationHandler = createLabelSuccessHandler,
    labelCreateType = 'project',
    workspaceType = 'project',
    labelsResponse = workspaceLabelsQueryResponse,
    searchTerm = '',
  } = {}) => {
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

  it('renders a palette of 21 colors', () => {
    createComponent();
    expect(findAllColors()).toHaveLength(21);
  });

  it('selects a color after clicking on colored block', async () => {
    createComponent();
    expect(findSelectedColorText().attributes('value')).toBe(DEFAULT_LABEL_COLOR);

    findAllColors().at(0).vm.$emit('click', new Event('mouseclick'));
    await nextTick();

    expect(findSelectedColor().attributes('value')).toBe('#009966');
  });

  it('shows correct color hex code after selecting a color', async () => {
    createComponent();
    expect(findSelectedColorText().attributes('value')).toBe(DEFAULT_LABEL_COLOR);

    findAllColors().at(0).vm.$emit('click', new Event('mouseclick'));
    await nextTick();

    expect(findSelectedColorText().attributes('value')).toBe(colors[0]);
  });

  it('disables a Create button if label title is not set', async () => {
    createComponent();
    findAllColors().at(0).vm.$emit('click', new Event('mouseclick'));
    await nextTick();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('disables a Create button if color is not set', async () => {
    createComponent();
    findLabelTitleInput().vm.$emit('input', 'Test title');
    findSelectedColorText().vm.$emit('input', '');
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

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not loader spinner after mutation is resolved', async () => {
      findCreateButton().vm.$emit('click');
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
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
