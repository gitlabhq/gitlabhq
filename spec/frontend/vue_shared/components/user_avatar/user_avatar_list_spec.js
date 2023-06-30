import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { TEST_HOST } from 'spec/test_constants';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const TEST_IMAGE_SIZE = 7;
const TEST_BREAKPOINT = 5;
const TEST_EMPTY_MESSAGE = 'Lorem ipsum empty';
const DEFAULT_EMPTY_MESSAGE = 'None';

const createUser = (id) => ({
  id,
  name: 'Lorem',
  username: 'lorem.ipsum',
  web_url: `${TEST_HOST}/${id}`,
  avatar_url: `${TEST_HOST}/${id}/avatar`,
});

const createList = (n) =>
  Array(n)
    .fill(1)
    .map((x, id) => createUser(id));
const createListCamelCase = (n) =>
  createList(n).map((user) => convertObjectPropsToCamelCase(user, { deep: true }));

describe('UserAvatarList', () => {
  let props;
  let wrapper;

  const factory = (options = {}) => {
    const propsData = {
      ...props,
      ...options.propsData,
    };

    wrapper = shallowMount(UserAvatarList, {
      ...options,
      propsData,
    });
  };

  const clickButton = () => {
    const button = wrapper.findComponent(GlButton);
    button.vm.$emit('click');
  };

  beforeEach(() => {
    props = { imgSize: TEST_IMAGE_SIZE };
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

    const linkProps = () =>
      wrapper.findAllComponents(UserAvatarLink).wrappers.map((x) => x.props());

    it('renders avatars when user has snake_case attributes', () => {
      const items = createList(20);
      factory({ propsData: { items } });

      expect(linkProps()).toEqual(
        items.map((x) =>
          expect.objectContaining({
            linkHref: x.web_url,
            imgSrc: x.avatar_url,
            imgAlt: x.name,
            tooltipText: x.name,
            imgSize: TEST_IMAGE_SIZE,
            popoverUserId: x.id,
            popoverUsername: x.username,
          }),
        ),
      );
    });

    it('renders avatars when user has camelCase attributes', () => {
      const items = createListCamelCase(20);
      factory({ propsData: { items } });

      expect(linkProps()).toEqual(
        items.map((x) =>
          expect.objectContaining({
            linkHref: x.webUrl,
            imgSrc: x.avatarUrl,
            imgAlt: x.name,
            tooltipText: x.name,
            imgSize: TEST_IMAGE_SIZE,
            popoverUserId: x.id,
            popoverUsername: x.username,
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

      const links = wrapper.findAllComponents(UserAvatarLink);

      expect(links.length).toEqual(props.items.length);
    });

    it('does not show button', () => {
      factory();

      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });

  describe('with breakpoint and length greater than breakpoint', () => {
    beforeEach(() => {
      props.breakpoint = TEST_BREAKPOINT;
      props.items = createList(TEST_BREAKPOINT + 1);
    });

    it('renders avatars up to breakpoint', () => {
      factory();

      const links = wrapper.findAllComponents(UserAvatarLink);

      expect(links.length).toEqual(TEST_BREAKPOINT);
    });

    it('does not emit any event on mount', async () => {
      factory();
      await nextTick();

      expect(wrapper.emitted()).toEqual({});
    });

    describe('with expand clicked', () => {
      beforeEach(() => {
        factory();
        clickButton();
      });

      it('renders all avatars', () => {
        const links = wrapper.findAllComponents(UserAvatarLink);

        expect(links.length).toEqual(props.items.length);
      });

      it('emits the `expanded` event', () => {
        expect(wrapper.emitted('expanded')).toHaveLength(1);
      });

      describe('with collapse clicked', () => {
        beforeEach(() => {
          clickButton();
        });

        it('renders avatars up to breakpoint', async () => {
          await nextTick();
          const links = wrapper.findAllComponents(UserAvatarLink);

          expect(links.length).toEqual(TEST_BREAKPOINT);
        });

        it('emits the `collapsed` event', () => {
          expect(wrapper.emitted('collapsed')).toHaveLength(1);
        });
      });
    });
  });
});
