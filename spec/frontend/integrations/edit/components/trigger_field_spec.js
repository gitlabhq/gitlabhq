import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';

import TriggerField from '~/integrations/edit/components/trigger_field.vue';
import { integrationTriggerEventTitles } from '~/integrations/constants';

Vue.use(Vuex);

describe('TriggerField', () => {
  let wrapper;
  let store;

  const defaultProps = {
    event: { name: 'push_events' },
    type: 'gitlab_slack_application',
  };
  const mockField = { name: 'push_channel' };

  const createComponent = ({ props = {}, isInheriting = false } = {}) => {
    store = new Vuex.Store({
      getters: {
        isInheriting: () => isInheriting,
      },
    });

    wrapper = shallowMount(TriggerField, {
      propsData: { ...defaultProps, ...props },
      store,
    });
  };

  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  describe('template', () => {
    it('renders enabled GlFormCheckbox', () => {
      createComponent();

      expect(findGlFormCheckbox().attributes('disabled')).toBeUndefined();
    });

    it('when isInheriting is true, renders disabled GlFormCheckbox', () => {
      createComponent({ isInheriting: true });

      expect(findGlFormCheckbox().attributes('disabled')).toBeDefined();
    });

    it('renders correct title', () => {
      createComponent();

      expect(findGlFormCheckbox().text()).toMatchInterpolatedText(
        integrationTriggerEventTitles[defaultProps.event.name],
      );
    });

    it('sets default value for hidden input', () => {
      createComponent();

      expect(findHiddenInput().attributes('value')).toBe('false');
    });

    it('renders hidden GlFormInput', () => {
      createComponent({
        props: {
          event: { name: 'push_events', field: mockField },
        },
      });

      expect(findGlFormInput().exists()).toBe(true);
      expect(findGlFormInput().isVisible()).toBe(false);
    });

    describe('checkbox is selected', () => {
      it('renders visible GlFormInput', async () => {
        createComponent({
          props: {
            event: { name: 'push_events', field: mockField },
          },
        });

        await findGlFormCheckbox().vm.$emit('input', true);

        expect(findGlFormInput().exists()).toBe(true);
        expect(findGlFormInput().isVisible()).toBe(true);
      });
    });

    it('toggles value of hidden input on checkbox input', async () => {
      createComponent({
        props: { event: { name: 'push_events', value: true } },
      });
      await nextTick;

      expect(findHiddenInput().attributes('value')).toBe('true');

      await findGlFormCheckbox().vm.$emit('input', false);

      expect(findHiddenInput().attributes('value')).toBe('false');
    });
  });
});
