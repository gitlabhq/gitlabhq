import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlAvatar, GlBadge, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { createRouter } from '~/ci/catalog/router/index';
import CiResourcesListItem from '~/ci/catalog/components/list/ci_resources_list_item.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { catalogSinglePageResponse } from '../../mock';

Vue.use(VueRouter);

const defaultEvent = { preventDefault: jest.fn, ctrlKey: false, metaKey: false };

describe('CiResourcesListItem', () => {
  let wrapper;
  let routerPush;

  const router = createRouter();
  const resource = catalogSinglePageResponse.data.ciCatalogResources.nodes[0];
  const componentList = {
    components: {
      nodes: [
        {
          id: 'gid://gitlab/Ci::Catalog::Resources::Component/2',
          name: 'test-component',
        },
        {
          id: 'gid://gitlab/Ci::Catalog::Resources::Component/1',
          name: 'component_two',
        },
      ],
    },
  };
  const release = {
    author: { id: 'author-id', name: 'author', username: 'author-username', webUrl: '/user/1' },
    createdAt: Date.now(),
    name: '1.0.0',
  };
  const defaultProps = {
    resource,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourcesListItem, {
      router,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findComponentNames = () => wrapper.findByTestId('ci-resource-component-names');
  const findResourceName = () => wrapper.findByTestId('ci-resource-link');
  const findResourceDescription = () => wrapper.findByText(defaultProps.resource.description);
  const findUserLink = () => wrapper.findByTestId('user-link');
  const findTimeAgoMessage = () => wrapper.findComponent(GlSprintf);
  const findFavorites = () => wrapper.findByTestId('stats-favorites');

  beforeEach(() => {
    routerPush = jest.spyOn(router, 'push').mockImplementation(() => {});
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the resource avatar and passes the right props', () => {
      const { icon, id, name } = defaultProps.resource;

      expect(findAvatar().exists()).toBe(true);
      expect(findAvatar().props()).toMatchObject({
        entityId: getIdFromGraphQLId(id),
        entityName: name,
        src: icon,
      });
    });

    it('renders the resource name and link', () => {
      expect(findResourceName().exists()).toBe(true);
      expect(findResourceName().attributes().href).toBe(defaultProps.resource.webPath);
    });

    it('renders the resource version badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it('renders the resource description', () => {
      expect(findResourceDescription().exists()).toBe(true);
    });
  });

  describe('components', () => {
    describe('when there are no components', () => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, versions: null } } });
      });

      it('does not render the component names', () => {
        expect(findComponentNames().exists()).toBe(false);
      });
    });

    describe('when there are components', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the component name template', () => {
        expect(findComponentNames().exists()).toBe(true);
      });

      it('renders the correct component names', () => {
        expect(findComponentNames().text()).toContain(componentList.components.nodes[0].name);
        expect(findComponentNames().text()).toContain(componentList.components.nodes[1].name);
      });
    });
  });

  describe('release time', () => {
    describe('when there is no release data', () => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, versions: null } } });
      });

      it('does not render the release', () => {
        expect(findTimeAgoMessage().exists()).toBe(false);
      });

      it('renders the generic `unreleased` badge', () => {
        expect(findBadge().exists()).toBe(true);
        expect(findBadge().text()).toBe('Unreleased');
      });
    });

    describe('when there is release data', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the user link', () => {
        expect(findUserLink().exists()).toBe(true);
        expect(findUserLink().attributes('href')).toBe(release.author.webUrl);
      });

      it('the user link has the correct attributes', () => {
        expect(findUserLink().attributes()).toEqual({
          'data-name': release.author.name,
          'data-username': release.author.username,
          'data-testid': 'user-link',
          href: release.author.webUrl,
          class: 'js-user-link',
        });
      });

      it('the user link renders the author name', () => {
        expect(findUserLink().text()).toBe(release.author.name);
      });

      it('renders the time since the resource was released', () => {
        expect(findTimeAgoMessage().exists()).toBe(true);
      });

      it('renders the version badge', () => {
        expect(findBadge().exists()).toBe(true);
        expect(findBadge().text()).toBe(release.name);
      });
    });
  });

  describe('when clicking on an item title', () => {
    describe('without holding down a modifier key', () => {
      it('navigates to the details page in the same tab', async () => {
        createComponent();
        await findResourceName().vm.$emit('click', defaultEvent);

        expect(routerPush).toHaveBeenCalledWith({
          path: cleanLeadingSeparator(resource.webPath),
        });
      });
    });

    describe.each`
      keyName
      ${'ctrlKey'}
      ${'metaKey'}
    `('when $keyName is being held down', ({ keyName }) => {
      beforeEach(async () => {
        createComponent();
        await findResourceName().vm.$emit('click', { ...defaultEvent, [keyName]: true });
      });

      it('does not call VueRouter push', () => {
        expect(routerPush).not.toHaveBeenCalled();
      });
    });
  });

  describe('when clicking on an item avatar', () => {
    beforeEach(async () => {
      createComponent();

      await findAvatar().vm.$emit('click', defaultEvent);
    });

    it('navigates to the details page', () => {
      expect(routerPush).toHaveBeenCalledWith({ path: cleanLeadingSeparator(resource.webPath) });
    });
  });

  describe('statistics', () => {
    describe('starrers link button', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the correct link to starrers', () => {
        expect(findFavorites().attributes('href')).toBe(resource.starrersPath);
      });

      it('has the correct attributes', () => {
        expect(findFavorites().attributes('icon')).toBe('star-o');
        expect(findFavorites().attributes('size')).toBe('small');
        expect(findFavorites().attributes('variant')).toBe('link');
        expect(findFavorites().attributes('title')).toBe('Stars');
      });

      it('has the correct styling', () => {
        expect(findFavorites().classes()).toEqual(['gl-reset-color!']);
      });
    });

    describe('when there are no statistics', () => {
      it('render favorites as 0', () => {
        createComponent({
          props: {
            resource: {
              ...resource,
              starCount: 0,
            },
          },
        });

        expect(findFavorites().exists()).toBe(true);
        expect(findFavorites().text()).toBe('0');
      });
    });

    describe('where there are statistics', () => {
      it('render favorites', () => {
        createComponent();

        expect(findFavorites().exists()).toBe(true);
        expect(findFavorites().text()).toBe(String(defaultProps.resource.starCount));
      });
    });
  });
});
