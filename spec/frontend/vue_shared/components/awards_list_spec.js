import { mount } from '@vue/test-utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

const createUser = (id, name) => ({ id, name });
const createAward = (name, user) => ({ name, user });

const USERS = {
  root: createUser(1, 'Root'),
  ada: createUser(2, 'Ada'),
  marie: createUser(3, 'Marie'),
  jane: createUser(4, 'Jane'),
  leonardo: createUser(5, 'Leonardo'),
  donatello: createUser(6, 'Donatello'),
  michelangelo: createUser(7, 'Michelangelo'),
  raphael: createUser(8, 'Raphael'),
  homer: createUser(9, 'Homer'),
  marge: createUser(10, 'Marge'),
  bart: createUser(11, 'Bart'),
  lisa: createUser(12, 'Lisa'),
  maggie: createUser(13, 'Maggie'),
  bort: createUser(14, 'Bort'),
};

const EMOJI_SMILE = 'smile';
const EMOJI_OK = 'ok_hand';
const EMOJI_A = 'a';
const EMOJI_B = 'b';
const EMOJI_CACTUS = 'cactus';
const EMOJI_100 = '100';
const EMOJI_RACEHORSE = 'racehorse';

const TEST_AWARDS = [
  createAward(EMOJI_SMILE, USERS.ada),
  createAward(EMOJI_OK, USERS.ada),
  createAward(EMOJI_THUMBS_UP, USERS.ada),
  createAward(EMOJI_THUMBS_DOWN, USERS.ada),
  createAward(EMOJI_SMILE, USERS.jane),
  createAward(EMOJI_OK, USERS.jane),
  createAward(EMOJI_OK, USERS.leonardo),
  createAward(EMOJI_THUMBS_UP, USERS.leonardo),
  createAward(EMOJI_THUMBS_UP, USERS.marie),
  createAward(EMOJI_THUMBS_DOWN, USERS.marie),
  createAward(EMOJI_THUMBS_DOWN, USERS.root),
  createAward(EMOJI_THUMBS_DOWN, USERS.donatello),

  createAward(EMOJI_OK, USERS.root),
  // Test that emoji list preserves order of occurrence, not alphabetical order
  createAward(EMOJI_CACTUS, USERS.root),
  createAward(EMOJI_A, USERS.marie),
  createAward(EMOJI_B, USERS.root),
  createAward(EMOJI_100, USERS.ada),

  // test when number of awards is > 10
  createAward(EMOJI_RACEHORSE, USERS.donatello),
  createAward(EMOJI_RACEHORSE, USERS.michelangelo),
  createAward(EMOJI_RACEHORSE, USERS.raphael),
  createAward(EMOJI_RACEHORSE, USERS.homer),
  createAward(EMOJI_RACEHORSE, USERS.marge),
  createAward(EMOJI_RACEHORSE, USERS.bart),
  createAward(EMOJI_RACEHORSE, USERS.lisa),
  createAward(EMOJI_RACEHORSE, USERS.maggie),
  createAward(EMOJI_RACEHORSE, USERS.bort),
  createAward(EMOJI_RACEHORSE, USERS.ada),
  createAward(EMOJI_RACEHORSE, USERS.jane),
  createAward(EMOJI_RACEHORSE, USERS.leonardo),
  createAward(EMOJI_RACEHORSE, USERS.marie),
  // it's important for test purposes that this is the last racehorse emoji awarded
  createAward(EMOJI_RACEHORSE, USERS.root),
];
const TEST_AWARDS_LENGTH = [
  EMOJI_SMILE,
  EMOJI_OK,
  EMOJI_THUMBS_UP,
  EMOJI_THUMBS_DOWN,
  EMOJI_A,
  EMOJI_B,
  EMOJI_CACTUS,
  EMOJI_100,
  EMOJI_RACEHORSE,
].length;
const TEST_ADD_BUTTON_CLASS = 'js-test-add-button-class';

const REACTION_CONTROL_CLASSES = [
  'btn',
  'gl-mr-3',
  'gl-my-2',
  'btn-default',
  'btn-md',
  'gl-button',
];

describe('vue_shared/components/awards_list', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(AwardsList, { propsData: props });
  };
  const matchingEmojiTag = (name) => expect.stringMatching(`gl-emoji data-name="${name}"`);
  const findAwardButtons = () => wrapper.findAll('[data-testid="award-button"]');
  const findAwardsData = () =>
    findAwardButtons().wrappers.map((x) => {
      return {
        classes: x.classes(),
        title: x.attributes('title'),
        emojiName: x.attributes('data-emoji-name'),
        html: x.find('[data-testid="award-html"]').html(),
        count: Number(x.find('.js-counter').text()),
      };
    });
  const findAddAwardButton = () => wrapper.find('[data-testid="emoji-picker"]');

  describe('default', () => {
    beforeEach(() => {
      createComponent({
        awards: TEST_AWARDS,
        canAwardEmoji: true,
        currentUserId: USERS.root.id,
        addButtonClass: TEST_ADD_BUTTON_CLASS,
      });
    });
    it('shows awards in correct order', () => {
      expect(findAwardsData()).toEqual([
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 3,
          html: matchingEmojiTag(EMOJI_THUMBS_UP),
          title: `Ada, Leonardo, and Marie reacted with :${EMOJI_THUMBS_UP}:`,
          emojiName: EMOJI_THUMBS_UP,
        },
        {
          classes: expect.arrayContaining([...REACTION_CONTROL_CLASSES, 'selected']),
          count: 4,
          html: matchingEmojiTag(EMOJI_THUMBS_DOWN),
          title: `Ada, Marie, you, and Donatello reacted with :${EMOJI_THUMBS_DOWN}:`,
          emojiName: EMOJI_THUMBS_DOWN,
        },
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 1,
          html: matchingEmojiTag(EMOJI_100),
          title: `Ada reacted with :${EMOJI_100}:`,
          emojiName: EMOJI_100,
        },
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 2,
          html: matchingEmojiTag(EMOJI_SMILE),
          title: `Ada and Jane reacted with :${EMOJI_SMILE}:`,
          emojiName: EMOJI_SMILE,
        },
        {
          classes: expect.arrayContaining([...REACTION_CONTROL_CLASSES, 'selected']),
          count: 4,
          html: matchingEmojiTag(EMOJI_OK),
          title: `Ada, Jane, Leonardo, and you reacted with :${EMOJI_OK}:`,
          emojiName: EMOJI_OK,
        },
        {
          classes: expect.arrayContaining([...REACTION_CONTROL_CLASSES, 'selected']),
          count: 1,
          html: matchingEmojiTag(EMOJI_CACTUS),
          title: `You reacted with :${EMOJI_CACTUS}:`,
          emojiName: EMOJI_CACTUS,
        },
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 1,
          html: matchingEmojiTag(EMOJI_A),
          title: `Marie reacted with :${EMOJI_A}:`,
          emojiName: EMOJI_A,
        },
        {
          classes: expect.arrayContaining([...REACTION_CONTROL_CLASSES, 'selected']),
          count: 1,
          html: matchingEmojiTag(EMOJI_B),
          title: `You reacted with :${EMOJI_B}:`,
          emojiName: EMOJI_B,
        },
        {
          classes: expect.arrayContaining([...REACTION_CONTROL_CLASSES, 'selected']),
          count: 14,
          html: matchingEmojiTag(EMOJI_RACEHORSE),
          title: `Donatello, Michelangelo, Raphael, Homer, Marge, Bart, Lisa, Maggie, Bort, you, and 4 more reacted with :${EMOJI_RACEHORSE}:`,
          emojiName: EMOJI_RACEHORSE,
        },
      ]);
    });

    it('with award clicked, it emits award', () => {
      expect(wrapper.emitted().award).toBeUndefined();

      findAwardButtons().at(3).vm.$emit('click');

      expect(wrapper.emitted().award).toEqual([[EMOJI_SMILE]]);
    });

    it('with numeric award clicked, it emits award as is', () => {
      expect(wrapper.emitted().award).toBeUndefined();

      findAwardButtons().at(2).vm.$emit('click');

      expect(wrapper.emitted().award).toEqual([[EMOJI_100]]);
    });

    it('shows add award button', () => {
      const btn = findAddAwardButton();

      expect(btn.exists()).toBe(true);
    });
  });

  describe('with no awards', () => {
    beforeEach(() => {
      createComponent({
        awards: [],
        canAwardEmoji: true,
      });
    });

    it('has no award buttons', () => {
      expect(findAwardButtons().length).toBe(0);
    });
  });

  describe('when cannot award emoji', () => {
    beforeEach(() => {
      createComponent({
        awards: [createAward(EMOJI_CACTUS, USERS.root.id)],
        canAwardEmoji: false,
        currentUserId: USERS.marie.id,
      });
    });

    it('does not have add button', () => {
      expect(findAddAwardButton().exists()).toBe(false);
    });
  });

  describe('with no user', () => {
    beforeEach(() => {
      createComponent({
        awards: TEST_AWARDS,
        canAwardEmoji: false,
      });
    });

    it('disables award buttons', () => {
      const buttons = findAwardButtons();

      expect(buttons.length).toBe(TEST_AWARDS_LENGTH);
      expect(buttons.wrappers.every((x) => x.classes('disabled'))).toBe(true);
    });
  });

  describe('with default awards', () => {
    beforeEach(() => {
      createComponent({
        awards: [createAward(EMOJI_SMILE, USERS.marie), createAward(EMOJI_100, USERS.marie)],
        canAwardEmoji: true,
        currentUserId: USERS.root.id,
        // Let's assert that it puts thumbsup and thumbsdown in the right order still
        defaultAwards: [EMOJI_THUMBS_DOWN, EMOJI_100, EMOJI_THUMBS_UP],
      });
    });

    it('shows awards in correct order', () => {
      expect(findAwardsData()).toEqual([
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 0,
          html: matchingEmojiTag(EMOJI_THUMBS_UP),
          title: '',
          emojiName: EMOJI_THUMBS_UP,
        },
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 0,
          html: matchingEmojiTag(EMOJI_THUMBS_DOWN),
          title: '',
          emojiName: EMOJI_THUMBS_DOWN,
        },
        // We expect the EMOJI_100 before the EMOJI_SMILE because it was given as a defaultAward
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 1,
          html: matchingEmojiTag(EMOJI_100),
          title: `Marie reacted with :${EMOJI_100}:`,
          emojiName: EMOJI_100,
        },
        {
          classes: expect.arrayContaining(REACTION_CONTROL_CLASSES),
          count: 1,
          html: matchingEmojiTag(EMOJI_SMILE),
          title: `Marie reacted with :${EMOJI_SMILE}:`,
          emojiName: EMOJI_SMILE,
        },
      ]);
    });
  });
});
