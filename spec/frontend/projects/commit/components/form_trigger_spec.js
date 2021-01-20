import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import FormTrigger from '~/projects/commit/components/form_trigger.vue';
import eventHub from '~/projects/commit/event_hub';

const displayText = '_display_text_';

const createComponent = () => {
  return shallowMount(FormTrigger, {
    provide: { displayText },
    propsData: { openModal: '_open_modal_' },
  });
};

describe('FormTrigger', () => {
  let wrapper;
  let spy;

  beforeEach(() => {
    spy = jest.spyOn(eventHub, '$emit');
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLink = () => wrapper.find(GlLink);

  describe('displayText', () => {
    it('includes the correct displayText for the link', () => {
      expect(findLink().text()).toBe(displayText);
    });
  });

  describe('clicking the link', () => {
    it('emits openModal', () => {
      findLink().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('_open_modal_');
    });
  });
});
