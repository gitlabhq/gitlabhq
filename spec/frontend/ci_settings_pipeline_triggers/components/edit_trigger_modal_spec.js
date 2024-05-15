import { GlModal, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EditTriggerModal from '~/ci_settings_pipeline_triggers/components/edit_trigger_modal.vue';

const TEST_MODAL_ID = 'test-modal-id';
const TEST_TRIGGER = {
  id: 5,
  token: '12345',
  description: 'A boring description',
};
const TEST_TRIGGER_NEW = {
  id: 7,
  token: '67890',
  description: 'A cool description',
};

describe('EditTriggerModal', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(EditTriggerModal, {
      propsData: {
        modalId: TEST_MODAL_ID,
        trigger: TEST_TRIGGER,
        ...propsData,
      },
      stubs: {
        GlModal,
        GlFormGroup,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findToken = () => wrapper.findComponent('[id=edit_trigger_token]');
  const findDescription = () => wrapper.findComponent('[id=edit_trigger_description]');
  const findFormFields = () => {
    return {
      token: findToken().text(),
      description: findDescription().attributes('value'),
    };
  };

  const updateDescription = async (val) => {
    findDescription().vm.$emit('input', val);
    await nextTick();
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders modal', () => {
      expect(findModal().props()).toMatchObject({
        modalId: TEST_MODAL_ID,
        title: 'Update Trigger',
      });
    });

    it('renders form', () => {
      expect(findFormFields()).toEqual({
        token: TEST_TRIGGER.token,
        description: TEST_TRIGGER.description,
      });
    });

    it('does not emit anything', () => {
      expect(wrapper.emitted()).toEqual({});
    });
  });

  describe('when form changed and submitted', () => {
    beforeEach(async () => {
      createComponent();

      await updateDescription('Lorem ipsum');

      findModal().vm.$emit('primary');
    });

    it('emits submit event', () => {
      expect(wrapper.emitted()).toEqual({
        submit: [[{ ...TEST_TRIGGER, description: 'Lorem ipsum' }]],
      });
    });
  });

  describe('when trigger prop changes', () => {
    beforeEach(async () => {
      createComponent();

      wrapper.setProps({ trigger: TEST_TRIGGER_NEW });
      await nextTick();
    });

    it('renders updated form', () => {
      expect(findFormFields()).toEqual({
        token: TEST_TRIGGER_NEW.token,
        description: TEST_TRIGGER_NEW.description,
      });
    });
  });
});
