import { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { resetHTMLFixture } from 'helpers/fixtures';
import { useFakeDate } from 'helpers/fake_date';
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders `SetStatusForm` component and passes expected props', () => {
    createComponent();

    expect(cloneDeep(findSetStatusForm().props())).toMatchObject({
      defaultEmoji: 'speech_balloon',
      emoji: defaultProvide.fields.emoji.value,
      message: defaultProvide.fields.message.value,
      availability: true,
      clearStatusAfter: NEVER_TIME_RANGE,
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

  describe('when clear status after dropdown is set to `Never`', () => {
    it('renders hidden clear status after input with value unset', () => {
      createComponent();

      expect(
        findInput(defaultProvide.fields.clearStatusAfter.name).attributes('value'),
      ).toBeUndefined();
    });
  });

  describe('when clear status after dropdown has a value selected', () => {
    it('renders hidden clear status after input with value set', async () => {
      createComponent();

      findSetStatusForm().vm.$emit('clear-status-after-click', TIME_RANGES_WITH_NEVER[1]);

      await nextTick();

      expect(findInput(defaultProvide.fields.clearStatusAfter.name).attributes('value')).toBe(
        TIME_RANGES_WITH_NEVER[1].shortcut,
      );
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

  describe('when form is successfully submitted', () => {
    // 2022-09-02 00:00:00 UTC
    useFakeDate(2022, 8, 2);

    const form = document.createElement('form');
    form.classList.add('js-edit-user');

    beforeEach(async () => {
      document.body.appendChild(form);
      createComponent();

      const oneDay = TIME_RANGES_WITH_NEVER[4];

      findSetStatusForm().vm.$emit('clear-status-after-click', oneDay);

      await nextTick();

      form.dispatchEvent(new Event('ajax:success'));
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('updates clear status after dropdown to `Never`', () => {
      expect(findSetStatusForm().props('clearStatusAfter')).toBe(NEVER_TIME_RANGE);
    });

    it('updates `currentClearStatusAfter` prop', () => {
      expect(findSetStatusForm().props('currentClearStatusAfter')).toBe('2022-09-03 00:00:00 UTC');
    });
  });
});
