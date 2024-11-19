import $ from 'jquery';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import SetStatusForm from '~/set_status_modal/set_status_form.vue';
import { NEVER_TIME_RANGE } from '~/set_status_modal/constants';
import EmojiPicker from '~/emoji/components/picker.vue';
import { timeRanges } from '~/vue_shared/constants';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import { EMOJI_THUMBS_UP } from '~/emoji/constants';

const [thirtyMinutes, , , oneDay] = timeRanges;

describe('SetStatusForm', () => {
  let wrapper;

  const defaultPropsData = {
    defaultEmoji: 'speech_balloon',
    emoji: EMOJI_THUMBS_UP,
    message: 'Foo bar',
    availability: false,
  };

  const createComponent = async ({ propsData = {} } = {}) => {
    wrapper = mountExtended(SetStatusForm, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });

    await waitForPromises();
  };

  const findMessageInput = () =>
    wrapper.findByPlaceholderText(SetStatusForm.i18n.statusMessagePlaceholder);
  const findSelectedEmoji = (emoji) =>
    wrapper.findByTestId('selected-emoji').find(`gl-emoji[data-name="${emoji}"]`);

  it('sets up emoji autocomplete for the message input', async () => {
    const gfmAutoCompleteSetupSpy = jest.spyOn(GfmAutoComplete.prototype, 'setup');

    await createComponent();

    expect(gfmAutoCompleteSetupSpy).toHaveBeenCalledWith($(findMessageInput().element), {
      emojis: true,
    });
  });

  describe('when emoji is set', () => {
    it('displays emoji', async () => {
      await createComponent();

      expect(findSelectedEmoji(defaultPropsData.emoji).exists()).toBe(true);
    });
  });

  describe('when emoji is not set and message is changed', () => {
    it('displays default emoji', async () => {
      await createComponent({
        propsData: {
          emoji: '',
        },
      });

      await findMessageInput().trigger('keyup');

      expect(findSelectedEmoji(defaultPropsData.defaultEmoji).exists()).toBe(true);
    });
  });

  describe('when message is set', () => {
    it('displays filled in message input', async () => {
      await createComponent();

      expect(findMessageInput().element.value).toBe(defaultPropsData.message);
    });
  });

  describe('clear status after dropdown toggle button text', () => {
    useFakeDate(2022, 11, 5);

    describe('when clear status after has previously been set', () => {
      describe('when date is today', () => {
        it('displays time that status will clear', async () => {
          await createComponent({
            propsData: {
              currentClearStatusAfter: '2022-12-05T11:00:00Z',
            },
          });

          expect(wrapper.findByRole('button', { name: '11:00 AM' }).exists()).toBe(true);
        });
      });

      describe('when date is not today', () => {
        it('displays date and time that status will clear', async () => {
          await createComponent({
            propsData: {
              currentClearStatusAfter: '2022-12-06T11:00:00Z',
            },
          });

          expect(wrapper.findByRole('button', { name: 'Dec 6, 2022, 11:00 AM' }).exists()).toBe(
            true,
          );
        });
      });

      describe('when a new option is choose from the dropdown', () => {
        describe('when chosen option is today', () => {
          it('displays chosen option as time', async () => {
            await createComponent({
              propsData: {
                clearStatusAfter: thirtyMinutes,
                currentClearStatusAfter: '2022-12-05T11:00:00Z',
              },
            });

            expect(wrapper.findByRole('button', { name: '12:30 AM' }).exists()).toBe(true);
          });
        });

        describe('when chosen option is not today', () => {
          it('displays chosen option as date and time', async () => {
            await createComponent({
              propsData: {
                clearStatusAfter: oneDay,
                currentClearStatusAfter: '2022-12-06T11:00:00Z',
              },
            });

            expect(wrapper.findByRole('button', { name: 'Dec 6, 2022, 12:00 AM' }).exists()).toBe(
              true,
            );
          });
        });
      });
    });

    describe('when clear status after has not been set', () => {
      it('displays `Never`', async () => {
        await createComponent();

        expect(wrapper.findByRole('button', { name: NEVER_TIME_RANGE.label }).exists()).toBe(true);
      });
    });
  });

  describe('when emoji is changed', () => {
    beforeEach(async () => {
      await createComponent();

      wrapper.findComponent(EmojiPicker).vm.$emit('click', defaultPropsData.emoji);
    });

    it('emits `emoji-click` event', () => {
      expect(wrapper.emitted('emoji-click')).toEqual([[defaultPropsData.emoji]]);
    });
  });

  describe('when message is changed', () => {
    it('emits `message-input` event', async () => {
      await createComponent();

      const newMessage = 'Foo bar baz';

      await findMessageInput().setValue(newMessage);

      expect(wrapper.emitted('message-input')).toEqual([[newMessage]]);
    });
  });

  describe('when availability checkbox is changed', () => {
    it('emits `availability-input` event', async () => {
      await createComponent();

      await wrapper
        .findByLabelText(
          `${SetStatusForm.i18n.availabilityCheckboxLabel} ${SetStatusForm.i18n.availabilityCheckboxHelpText}`,
        )
        .setChecked();

      expect(wrapper.emitted('availability-input')).toEqual([[true]]);
    });
  });

  describe('when `Clear status after` dropdown is changed', () => {
    it('emits `clear-status-after-click`', async () => {
      await createComponent();

      await wrapper.findByTestId('listbox-item-thirtyMinutes').trigger('click');

      expect(wrapper.emitted('clear-status-after-click')).toEqual([[thirtyMinutes]]);
    });
  });

  describe('when clear status button is clicked', () => {
    beforeEach(async () => {
      await createComponent();

      await wrapper
        .findByRole('button', { name: SetStatusForm.i18n.clearStatusButtonLabel })
        .trigger('click');
    });

    it('clears emoji and message', () => {
      expect(wrapper.emitted('emoji-click')).toEqual([['']]);
      expect(wrapper.emitted('message-input')).toEqual([['']]);
      expect(wrapper.findByTestId('no-emoji-placeholder').exists()).toBe(true);
    });
  });
});
