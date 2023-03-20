import { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserProfileSetStatusWrapper from '~/set_status_modal/user_profile_set_status_wrapper.vue';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import { TIME_RANGES_WITH_NEVER, NEVER_TIME_RANGE } from '~/set_status_modal/constants';

describe('UserProfileSetStatusWrapper', () => {
  let wrapper;

  const defaultProvide = {
    fields: {
      emoji: { name: 'user[status][emoji]', id: 'user_status_emoji', value: '8ball' },
      message: { name: 'user[status][message]', id: 'user_status_message', value: 'foo bar' },
      availability: {
        name: 'user[status][availability]',
        id: 'user_status_availability',
        value: 'busy',
      },
      clearStatusAfter: {
        name: 'user[status][clear_status_after]',
        id: 'user_status_clear_status_after',
        value: '2022-09-03 03:06:26 UTC',
      },
    },
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(UserProfileSetStatusWrapper, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findInput = (name) => wrapper.find(`[name="${name}"]`);
  const findSetStatusForm = () => wrapper.findComponent(SetStatusForm);

  it('renders `SetStatusForm` component and passes expected props', () => {
    createComponent();

    expect(cloneDeep(findSetStatusForm().props())).toMatchObject({
      defaultEmoji: 'speech_balloon',
      emoji: defaultProvide.fields.emoji.value,
      message: defaultProvide.fields.message.value,
      availability: true,
      clearStatusAfter: null,
      currentClearStatusAfter: defaultProvide.fields.clearStatusAfter.value,
    });
  });

  it.each`
    input
    ${'emoji'}
    ${'message'}
    ${'availability'}
  `('renders hidden $input input with value set', ({ input }) => {
    createComponent();

    expect(findInput(defaultProvide.fields[input].name).attributes('value')).toBe(
      defaultProvide.fields[input].value,
    );
  });

  describe('when clear status after has previously been set', () => {
    describe('when clear status after dropdown is not set', () => {
      it('does not render hidden clear status after input', () => {
        createComponent();

        expect(findInput(defaultProvide.fields.clearStatusAfter.name).exists()).toBe(false);
      });
    });

    describe('when clear status after dropdown is set to `Never`', () => {
      it('renders hidden clear status after input with value unset', async () => {
        createComponent();

        findSetStatusForm().vm.$emit('clear-status-after-click', NEVER_TIME_RANGE);

        await nextTick();

        expect(
          findInput(defaultProvide.fields.clearStatusAfter.name).attributes('value'),
        ).toBeUndefined();
      });
    });

    describe('when clear status after dropdown is set to a time range', () => {
      it('renders hidden clear status after input with value set', async () => {
        createComponent();

        findSetStatusForm().vm.$emit('clear-status-after-click', TIME_RANGES_WITH_NEVER[1]);

        await nextTick();

        expect(findInput(defaultProvide.fields.clearStatusAfter.name).attributes('value')).toBe(
          TIME_RANGES_WITH_NEVER[1].shortcut,
        );
      });
    });
  });

  describe('when emoji is changed', () => {
    it('updates hidden emoji input value', async () => {
      createComponent();

      const newEmoji = 'basketball';

      findSetStatusForm().vm.$emit('emoji-click', newEmoji);

      await nextTick();

      expect(findInput(defaultProvide.fields.emoji.name).attributes('value')).toBe(newEmoji);
    });
  });

  describe('when message is changed', () => {
    it('updates hidden message input value', async () => {
      createComponent();

      const newMessage = 'foo bar baz';

      findSetStatusForm().vm.$emit('message-input', newMessage);

      await nextTick();

      expect(findInput(defaultProvide.fields.message.name).attributes('value')).toBe(newMessage);
    });
  });
});
