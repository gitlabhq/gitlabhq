import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { TEST_HOST } from 'spec/test_constants';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

const TEST_IMAGE_SIZE = 7;
const TEST_BREAKPOINT = 5;
const TEST_EMPTY_MESSAGE = 'Lorem ipsum empty';
const DEFAULT_EMPTY_MESSAGE = 'None';

const createUser = id => ({
  id,
  name: 'Lorem',
  web_url: `${TEST_HOST}/${id}`,
  avatar_url: `${TEST_HOST}/${id}/avatar`,
});
const createList = n =>
  Array(n)
    .fill(1)
    .map((x, id) => createUser(id));

const localVue = createLocalVue();

describe('UserAvatarList', () => {
  let props;
  let wrapper;

  const factory = (options = {}) => {
    const propsData = {
      ...props,
      ...options.propsData,
    };

    wrapper = shallowMount(localVue.extend(UserAvatarList), {
      ...options,
      localVue,
      propsData,
    });
  };

  const clickButton = () => {
    const button = wrapper.find(GlButton);
    button.vm.$emit('click');
  };

  beforeEach(() => {
    props = { imgSize: TEST_IMAGE_SIZE };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('empty text', () => {
    it('shows when items are empty', () => {
      factory({ propsData: { items: [] } });

      expect(wrapper.text()).toContain(DEFAULT_EMPTY_MESSAGE);
    });

    it('does not show when items are not empty', () => {
      factory({ propsData: { items: createList(1) } });

      expect(wrapper.text()).not.toContain(DEFAULT_EMPTY_MESSAGE);
    });

    it('can be set in props', () => {
      factory({ propsData: { items: [], emptyText: TEST_EMPTY_MESSAGE } });

      expect(wrapper.text()).toContain(TEST_EMPTY_MESSAGE);
    });
  });

  describe('with no breakpoint', () => {
    beforeEach(() => {
      props.breakpoint = 0;
    });

    it('renders avatars', () => {
      const items = createList(20);
      factory({ propsData: { items } });

      const links = wrapper.findAll(UserAvatarLink);
      const linkProps = links.wrappers.map(x => x.props());

      expect(linkProps).toEqual(
        items.map(x =>
          expect.objectContaining({
            linkHref: x.web_url,
            imgSrc: x.avatar_url,
            imgAlt: x.name,
            tooltipText: x.name,
            imgSize: TEST_IMAGE_SIZE,
          }),
        ),
      );
    });
  });

  describe('with breakpoint and length equal to breakpoint', () => {
    beforeEach(() => {
      props.breakpoint = TEST_BREAKPOINT;
      props.items = createList(TEST_BREAKPOINT);
    });

    it('renders all avatars if length is <= breakpoint', () => {
      factory();

      const links = wrapper.findAll(UserAvatarLink);

      expect(links.length).toEqual(props.items.length);
    });

    it('does not show button', () => {
      factory();

      expect(wrapper.find(GlButton).exists()).toBe(false);
    });
  });

  describe('with breakpoint and length greater than breakpoint', () => {
    beforeEach(() => {
      props.breakpoint = TEST_BREAKPOINT;
      props.items = createList(TEST_BREAKPOINT + 1);
    });

    it('renders avatars up to breakpoint', () => {
      factory();

      const links = wrapper.findAll(UserAvatarLink);

      expect(links.length).toEqual(TEST_BREAKPOINT);
    });

    describe('with expand clicked', () => {
      beforeEach(() => {
        factory();
        clickButton();
      });

      it('renders all avatars', () => {
        const links = wrapper.findAll(UserAvatarLink);

        expect(links.length).toEqual(props.items.length);
      });

      it('with collapse clicked, it renders avatars up to breakpoint', () => {
        clickButton();

        return wrapper.vm.$nextTick(() => {
          const links = wrapper.findAll(UserAvatarLink);

          expect(links.length).toEqual(TEST_BREAKPOINT);
        });
      });
    });
  });
});
