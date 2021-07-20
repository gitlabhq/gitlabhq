import { mount } from '@vue/test-utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';

const createUser = (id, name) => ({ id, name });
const createAward = (name, user) => ({ name, user });

const USERS = {
  root: createUser(1, 'Root'),
  ada: createUser(2, 'Ada'),
  marie: createUser(3, 'Marie'),
  jane: createUser(4, 'Jane'),
  leonardo: createUser(5, 'Leonardo'),
};

const EMOJI_SMILE = 'smile';
const EMOJI_OK = 'ok_hand';
const EMOJI_THUMBSUP = 'thumbsup';
const EMOJI_THUMBSDOWN = 'thumbsdown';
const EMOJI_A = 'a';
const EMOJI_B = 'b';
const EMOJI_CACTUS = 'cactus';
const EMOJI_100 = '100';

const TEST_AWARDS = [
  createAward(EMOJI_SMILE, USERS.ada),
  createAward(EMOJI_OK, USERS.ada),
  createAward(EMOJI_THUMBSUP, USERS.ada),
  createAward(EMOJI_THUMBSDOWN, USERS.ada),
  createAward(EMOJI_SMILE, USERS.jane),
  createAward(EMOJI_OK, USERS.jane),
  createAward(EMOJI_OK, USERS.leonardo),
  createAward(EMOJI_THUMBSUP, USERS.leonardo),
  createAward(EMOJI_THUMBSUP, USERS.marie),
  createAward(EMOJI_THUMBSDOWN, USERS.marie),
  createAward(EMOJI_THUMBSDOWN, USERS.root),
  createAward(EMOJI_OK, USERS.root),
  // Test that emoji list preserves order of occurrence, not alphabetical order
  createAward(EMOJI_CACTUS, USERS.root),
  createAward(EMOJI_A, USERS.marie),
  createAward(EMOJI_B, USERS.root),
];
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createComponent = (props = {}) => {
    if (wrapper) {
      throw new Error('There should only be one wrapper created per test');
    }

    wrapper = mount(AwardsList, { propsData: props });
  };
  const matchingEmojiTag = (name) => expect.stringMatching(`gl-emoji data-name="${name}"`);
  const findAwardButtons = () => wrapper.findAll('[data-testid="award-button"]');
  const findAwardsData = () =>
    findAwardButtons().wrappers.map((x) => {
      return {
        classes: x.classes(),
        title: x.attributes('title'),
        html: x.find('[data-testid="award-html"]').html(),
        count: Number(x.find('.js-counter').text()),
      };
    });
  const findAddAwardButton = () => wrapper.find('.js-add-award');

  describe('default', () => {
    beforeEach(() => {
      createComponent({
        awards: TEST_AWARDS,
        canAwardEmoji: true,
        currentUserId: USERS.root.id,
        addButtonClass: TEST_ADD_BUTTON_CLASS,
      });
    });

    it('matches snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('shows awards in correct order', () => {
      expect(findAwardsData()).toEqual([
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 3,
          html: matchingEmojiTag(EMOJI_THUMBSUP),
          title: `Ada, Leonardo, and Marie reacted with :${EMOJI_THUMBSUP}:`,
        },
        {
          classes: [...REACTION_CONTROL_CLASSES, 'selected'],
          count: 3,
          html: matchingEmojiTag(EMOJI_THUMBSDOWN),
          title: `You, Ada, and Marie reacted with :${EMOJI_THUMBSDOWN}:`,
        },
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 2,
          html: matchingEmojiTag(EMOJI_SMILE),
          title: `Ada and Jane reacted with :${EMOJI_SMILE}:`,
        },
        {
          classes: [...REACTION_CONTROL_CLASSES, 'selected'],
          count: 4,
          html: matchingEmojiTag(EMOJI_OK),
          title: `You, Ada, Jane, and Leonardo reacted with :${EMOJI_OK}:`,
        },
        {
          classes: [...REACTION_CONTROL_CLASSES, 'selected'],
          count: 1,
          html: matchingEmojiTag(EMOJI_CACTUS),
          title: `You reacted with :${EMOJI_CACTUS}:`,
        },
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 1,
          html: matchingEmojiTag(EMOJI_A),
          title: `Marie reacted with :${EMOJI_A}:`,
        },
        {
          classes: [...REACTION_CONTROL_CLASSES, 'selected'],
          count: 1,
          html: matchingEmojiTag(EMOJI_B),
          title: `You reacted with :${EMOJI_B}:`,
        },
      ]);
    });

    it('with award clicked, it emits award', () => {
      expect(wrapper.emitted().award).toBeUndefined();

      findAwardButtons().at(2).vm.$emit('click');

      expect(wrapper.emitted().award).toEqual([[EMOJI_SMILE]]);
    });

    it('shows add award button', () => {
      const btn = findAddAwardButton();

      expect(btn.exists()).toBe(true);
      expect(btn.classes(TEST_ADD_BUTTON_CLASS)).toBe(true);
    });
  });

  describe('with numeric award', () => {
    beforeEach(() => {
      createComponent({
        awards: [createAward(EMOJI_100, USERS.ada)],
        canAwardEmoji: true,
        currentUserId: USERS.root.id,
      });
    });

    it('when clicked, it emits award as number', () => {
      expect(wrapper.emitted().award).toBeUndefined();

      findAwardButtons().at(0).vm.$emit('click');

      expect(wrapper.emitted().award).toEqual([[Number(EMOJI_100)]]);
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

      expect(buttons.length).toBe(7);
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
        defaultAwards: [EMOJI_THUMBSDOWN, EMOJI_100, EMOJI_THUMBSUP],
      });
    });

    it('shows awards in correct order', () => {
      expect(findAwardsData()).toEqual([
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 0,
          html: matchingEmojiTag(EMOJI_THUMBSUP),
          title: '',
        },
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 0,
          html: matchingEmojiTag(EMOJI_THUMBSDOWN),
          title: '',
        },
        // We expect the EMOJI_100 before the EMOJI_SMILE because it was given as a defaultAward
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 1,
          html: matchingEmojiTag(EMOJI_100),
          title: `Marie reacted with :${EMOJI_100}:`,
        },
        {
          classes: REACTION_CONTROL_CLASSES,
          count: 1,
          html: matchingEmojiTag(EMOJI_SMILE),
          title: `Marie reacted with :${EMOJI_SMILE}:`,
        },
      ]);
    });
  });
});
