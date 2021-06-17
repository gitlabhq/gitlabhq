import { GlLoadingIcon, GlLink } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import DropdownContentsCreateView from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_contents_create_view.vue';
import createLabelMutation from '~/vue_shared/components/sidebar/labels_select_widget/graphql/create_label.mutation.graphql';
import { mockSuggestedColors, createLabelSuccessfulResponse } from './mock_data';

jest.mock('~/flash');

const colors = Object.keys(mockSuggestedColors);

const localVue = createLocalVue();
Vue.use(VueApollo);

const userRecoverableError = {
  ...createLabelSuccessfulResponse,
  errors: ['Houston, we have a problem'],
};

const createLabelSuccessHandler = jest.fn().mockResolvedValue(createLabelSuccessfulResponse);
const createLabelUserRecoverableErrorHandler = jest.fn().mockResolvedValue(userRecoverableError);
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

  const createComponent = ({ mutationHandler = createLabelSuccessHandler } = {}) => {
    const mockApollo = createMockApollo([[createLabelMutation, mutationHandler]]);

    wrapper = shallowMount(DropdownContentsCreateView, {
      localVue,
      apolloProvider: mockApollo,
    });
  };

  beforeEach(() => {
    gon.suggested_label_colors = mockSuggestedColors;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a palette of 21 colors', () => {
    createComponent();
    expect(findAllColors()).toHaveLength(21);
  });

  it('selects a color after clicking on colored block', async () => {
    createComponent();
    expect(findSelectedColor().attributes('style')).toBeUndefined();

    findAllColors().at(0).vm.$emit('click', new Event('mouseclick'));
    await nextTick();

    expect(findSelectedColor().attributes('style')).toBe('background-color: rgb(0, 153, 102);');
  });

  it('shows correct color hex code after selecting a color', async () => {
    createComponent();
    expect(findSelectedColorText().attributes('value')).toBe('');

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
    await nextTick();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('does not render a loader spinner', () => {
    createComponent();
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('emits a `hideCreateView` event on Cancel button click', () => {
    createComponent();
    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted('hideCreateView')).toHaveLength(1);
  });

  describe('when label title and selected color are set', () => {
    beforeEach(() => {
      createComponent();
      fillLabelAttributes();
    });

    it('enables a Create button', () => {
      expect(findCreateButton().props('disabled')).toBe(false);
    });

    it('calls a mutation with correct parameters on Create button click', () => {
      findCreateButton().vm.$emit('click');
      expect(createLabelSuccessHandler).toHaveBeenCalledWith({
        color: '#009966',
        projectPath: '',
        title: 'Test title',
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

  it('calls createFlash is mutation has a user-recoverable error', async () => {
    createComponent({ mutationHandler: createLabelUserRecoverableErrorHandler });
    fillLabelAttributes();
    await nextTick();

    findCreateButton().vm.$emit('click');
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });

  it('calls createFlash is mutation was rejected', async () => {
    createComponent({ mutationHandler: createLabelErrorHandler });
    fillLabelAttributes();
    await nextTick();

    findCreateButton().vm.$emit('click');
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });
});
