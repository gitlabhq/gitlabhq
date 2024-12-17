import { GlFormInput, GlModal, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WarningModal from '~/projects/settings/repository/maintenance/warning_modal.vue';
import { stubComponent } from 'helpers/stub_component';

jest.mock('lodash/uniqueId', () => () => 'fake-id');

describe('WarningModal', () => {
  let wrapper;

  const defaultPropsData = {
    visible: false,
    confirmPhrase: 'confirm/phrase',
    title: 'some title',
    primaryText: 'Yes, remove blobs',
    confirmLoading: false,
  };

  const createComponent = (propsData) => {
    wrapper = mountExtended(WarningModal, {
      propsData: { ...defaultPropsData, ...propsData },
      stubs: { GlModal: stubComponent(GlModal) },
      scopedSlots: { default: '<p>Custom warning message</p>' },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFormInput = () => wrapper.findComponent(GlFormInput);
  const findListItems = () => wrapper.findAllByRole('listitem');

  beforeEach(() => createComponent());

  it('renders modal with correct props', () => {
    expect(findModal().props()).toMatchObject({
      visible: false,
      noFocusOnShow: true,
      modalId: 'fake-id',
      actionPrimary: {
        text: 'Yes, remove blobs',
        attributes: { variant: 'danger', disabled: true },
      },
      actionCancel: { text: 'Cancel' },
    });
  });

  describe('modal content', () => {
    it('displays correct title', () => {
      expect(findModal().text()).toContain('some title');
    });

    it('displays a list of warnings', () => {
      expect(findListItems().at(0).text()).toBe(
        'Open merge requests might fail to merge and require manual rebasing.',
      );
      expect(findListItems().at(1).text()).toBe(
        'Existing local clones are incompatible with the updated repository and must be re-cloned.',
      );
      expect(findListItems().at(2).text()).toBe(
        'Pipelines referencing old commit SHAs might break and require reconfiguration.',
      );
      expect(findListItems().at(3).text()).toBe(
        'Historical tags and branches based on the old commit history might not function correctly.',
      );
    });

    it('displays a confirm phrase', () => {
      expect(findModal().text()).toContain('Enter the following to confirm:');
      expect(findModal().text()).toContain('confirm/phrase');
    });
  });

  describe('when correct confirm phrase is used', () => {
    beforeEach(() => findFormInput().vm.$emit('input', defaultPropsData.confirmPhrase));

    it('enables the primary action', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });
  });

  describe('when incorrect confirm phrase is used', () => {
    beforeEach(() => findFormInput().vm.$emit('input', 'bar'));

    it('keeps the primary action disabled', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });
  });

  it('emits `confirm` event when primary button is emitted', () => {
    findModal().vm.$emit('primary', { preventDefault: jest.fn() });

    expect(wrapper.emitted('confirm')).toEqual([[]]);
  });

  describe('modal visibility handling', () => {
    it('resets userInput when modal is shown', async () => {
      findFormInput().vm.$emit('input', defaultPropsData.confirmPhrase);
      await nextTick();

      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);

      findModal().vm.$emit('show');
      await nextTick();

      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });
  });

  describe('slot content', () => {
    it('renders slot content in alert', () => {
      expect(findAlert().text()).toContain('Custom warning message');
    });
  });
});
