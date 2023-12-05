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
  const release = {
    author: { name: 'author', webUrl: '/user/1' },
    releasedAt: Date.now(),
    tagName: '1.0.0',
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

  describe('release time', () => {
    describe('when there is no release data', () => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, latestVersion: null } } });
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
        createComponent({ props: { resource: { ...resource, latestVersion: { ...release } } } });
      });

      it('renders the user link', () => {
        expect(findUserLink().exists()).toBe(true);
        expect(findUserLink().attributes('href')).toBe(release.author.webUrl);
      });

      it('renders the time since the resource was released', () => {
        expect(findTimeAgoMessage().exists()).toBe(true);
      });

      it('renders the version badge', () => {
        expect(findBadge().exists()).toBe(true);
        expect(findBadge().text()).toBe(release.tagName);
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
