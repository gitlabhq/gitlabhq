import AxiosMockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { userDataMock } from 'jest/notes/mock_data';
import EmojiPicker from '~/emoji/components/picker.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import awardsNote from '~/notes/components/note_awards_list.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(PiniaVuePlugin);

describe('Note Awards List', () => {
  let wrapper;
  let pinia;
  let mock;

  const awardsMock = [
    {
      name: 'flag_tz',
      user: { id: 1, name: 'Administrator', username: 'root' },
    },
    {
      name: 'cartwheel_tone3',
      user: { id: 12, name: 'Bobbie Stehr', username: 'erin' },
    },
  ];
  const toggleAwardPathMock = `${TEST_HOST}/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji`;

  const defaultProps = {
    awards: awardsMock,
    noteAuthorId: 2,
    noteId: '545',
    canAwardEmoji: false,
    toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
  };

  const findAddAward = () => wrapper.find('.js-add-award');
  const findAwardButton = () => wrapper.findByTestId('award-button');
  const findAllEmojiAwards = () => wrapper.findAll('gl-emoji');
  const findEmojiPicker = () => wrapper.findComponent(EmojiPicker);

  const createComponent = (props = defaultProps) => {
    wrapper = mountExtended(awardsNote, {
      pinia,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes().setUserData(userDataMock);
    useNotes().toggleAwardRequest.mockResolvedValue();
  });

  describe('Note Awards functionality', () => {
    beforeEach(() => {
      mock = new AxiosMockAdapter(axios);
      mock.onPost(toggleAwardPathMock).reply(HTTP_STATUS_OK, '');

      createComponent({
        awards: awardsMock,
        noteAuthorId: 2,
        noteId: '545',
        canAwardEmoji: true,
        toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('should render awarded emojis', () => {
      const emojiAwards = findAllEmojiAwards();

      expect(emojiAwards).toHaveLength(awardsMock.length);
      expect(emojiAwards.at(0).attributes('data-name')).toBe('flag_tz');
      expect(emojiAwards.at(1).attributes('data-name')).toBe('cartwheel_tone3');
    });

    it('should be possible to add new emoji', () => {
      expect(findEmojiPicker().exists()).toBe(true);
    });

    it('should be possible to remove awarded emoji', async () => {
      await findAwardButton().vm.$emit('click');

      const { toggleAwardPath, noteId } = defaultProps;
      expect(useNotes().toggleAwardRequest).toHaveBeenCalledWith({
        awardName: awardsMock[0].name,
        endpoint: toggleAwardPath,
        noteId,
      });
    });
  });

  describe('when the user name contains special HTML characters', () => {
    const createAwardEmoji = (_, index) => ({
      name: 'art',
      user: { id: index, name: `&<>"\`'-${index}`, username: `user-${index}` },
    });

    const customProps = {
      awards: awardsMock,
      noteAuthorId: 0,
      noteId: '545',
      canAwardEmoji: true,
      toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
    };

    it('should not escape special HTML characters twice when only 1 person awarded', () => {
      const awardsCopy = [...new Array(1)].map(createAwardEmoji);
      createComponent({
        ...customProps,
        awards: awardsCopy,
      });

      awardsCopy.forEach((award) => {
        expect(findAwardButton().attributes('title')).toContain(award.user.name);
      });
    });

    it('should not escape special HTML characters twice when 2 people awarded', () => {
      const awardsCopy = [...new Array(2)].map(createAwardEmoji);
      createComponent({
        ...customProps,
        awards: awardsCopy,
      });

      awardsCopy.forEach((award) => {
        expect(findAwardButton().attributes('title')).toContain(award.user.name);
      });
    });

    it('should not escape special HTML characters twice when more than 10 people awarded', () => {
      const awardsCopy = [...new Array(11)].map(createAwardEmoji);
      createComponent({
        ...customProps,
        awards: awardsCopy,
      });

      // Testing only the first 10 awards since 11 onward will not be displayed.
      awardsCopy.slice(0, 10).forEach((award) => {
        expect(findAwardButton().attributes('title')).toContain(award.user.name);
      });
    });
  });

  describe('when the user cannot award an emoji', () => {
    beforeEach(() => {
      createComponent({
        awards: awardsMock,
        noteAuthorId: 2,
        noteId: '545',
        canAwardEmoji: false,
        toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
      });
    });

    it('should display an award emoji button with a disabled class', () => {
      expect(findAwardButton().classes()).toContain('disabled');
    });

    it('should not be possible to add new emoji', () => {
      expect(findAddAward().exists()).toBe(false);
    });
  });
});
