import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import List from '~/custom_emoji/components/list.vue';
import DeleteItem from '~/custom_emoji/components/delete_item.vue';
import { CUSTOM_EMOJI } from '../mock_data';

jest.mock('~/lib/utils/datetime/locale_dateformat', () => ({
  localeDateFormat: {
    asDate: {
      format: (date) => date,
    },
  },
}));

Vue.config.ignoredElements = ['gl-emoji'];

let wrapper;

function createComponent(propsData = {}) {
  wrapper = mountExtended(List, {
    propsData: {
      customEmojis: CUSTOM_EMOJI,
      pageInfo: {},
      count: CUSTOM_EMOJI.length,
      userPermissions: { createCustomEmoji: true },
      ...propsData,
    },
    stubs: {
      GlEmoji: { template: '<div/>' },
    },
  });
}

describe('Custom emoji settings list component', () => {
  it('renders table of custom emoji', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('user permissions', () => {
    it.each`
      createCustomEmoji | visible
      ${true}           | ${true}
      ${false}          | ${false}
    `(
      'renders create new button if createCustomEmoji is $createCustomEmoji',
      ({ createCustomEmoji, visible }) => {
        createComponent({ userPermissions: { createCustomEmoji } });

        expect(wrapper.findByTestId('action-primary').exists()).toBe(visible);
      },
    );
  });

  describe('pagination', () => {
    it.each`
      emits                        | button          | pageInfo
      ${{ before: 'startCursor' }} | ${'prevButton'} | ${{ hasPreviousPage: true, startCursor: 'startCursor' }}
      ${{ after: 'endCursor' }}    | ${'nextButton'} | ${{ hasNextPage: true, endCursor: 'endCursor' }}
    `('emits $emits when $button is clicked', async ({ emits, button, pageInfo }) => {
      createComponent({ pageInfo });

      await wrapper.findByTestId(button).vm.$emit('click');

      expect(wrapper.emitted('input')[0]).toEqual([emits]);
    });
  });

  describe('delete button', () => {
    it.each`
      deleteCustomEmoji | rendersText          | renders
      ${true}           | ${'renders'}         | ${true}
      ${false}          | ${'does not render'} | ${false}
    `(
      '$rendersText delete button when deleteCustomEmoji is $deleteCustomEmoji',
      ({ deleteCustomEmoji, renders }) => {
        createComponent({
          customEmojis: [{ ...CUSTOM_EMOJI[0], userPermissions: { deleteCustomEmoji } }],
        });

        expect(wrapper.findComponent(DeleteItem).exists()).toBe(renders);
      },
    );
  });
});
