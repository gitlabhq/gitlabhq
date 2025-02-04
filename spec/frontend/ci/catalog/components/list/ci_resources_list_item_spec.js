import { update, cloneDeep } from 'lodash';
import { GlAvatar, GlBadge, GlSprintf, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createRouter } from '~/ci/catalog/router/index';
import CiResourcesListItem from '~/ci/catalog/components/list/ci_resources_list_item.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiVerificationBadge from '~/ci/catalog/components/shared/ci_verification_badge.vue';
import ProjectVisibilityIcon from '~/ci/catalog/components/shared/project_visibility_icon.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import TopicBadges from '~/vue_shared/components/topic_badges.vue';
import { catalogSinglePageResponse, longResourceDescription } from '../../mock';

const defaultEvent = { preventDefault: jest.fn, ctrlKey: false, metaKey: false };
const baseRoute = '/';
const resourcesPageComponentStub = {
  name: 'page-component',
  template: '<div>Hello</div>',
};

describe('CiResourcesListItem', () => {
  let wrapper;
  let routerPush;
  let router;

  const resource = catalogSinglePageResponse.data.ciCatalogResources.nodes[0];
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
        GlTruncate,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findMarkdown = () => wrapper.findComponent(Markdown);
  const findTimeAgoMessage = () => wrapper.findComponent(GlSprintf);
  const findTopicBadgesComponent = () => wrapper.findComponent(TopicBadges);
  const findVerificationBadge = () => wrapper.findComponent(CiVerificationBadge);
  const findVisibilityIcon = () => wrapper.findComponent(ProjectVisibilityIcon);

  const findComponentNames = () => wrapper.findByTestId('ci-resource-component-names');
  const findFavorites = () => wrapper.findByTestId('stats-favorites');
  const findResourceName = () => wrapper.findByTestId('ci-resource-link');
  const findUsage = () => wrapper.findByTestId('stats-usage');
  const findUserLink = () => wrapper.findByTestId('user-link');

  beforeEach(() => {
    router = createRouter(baseRoute, resourcesPageComponentStub);
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
      expect(findResourceName().attributes().href).toBe(`/${defaultProps.resource.fullPath}`);
    });

    it('renders the resource version badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it('renders the resource description', () => {
      const markdown = findMarkdown();
      expect(markdown.exists()).toBe(true);
      expect(markdown.props().markdown).toBe(defaultProps.resource.description);
    });

    it('renders a truncated resource description', () => {
      defaultProps.resource.description = longResourceDescription;
      createComponent();

      const markdown = findMarkdown();
      expect(markdown.props().markdown.length).toBe(260);
    });

    it('hides the resource description on mobile devices', () => {
      const markdown = findMarkdown();
      expect(markdown.classes()).toEqual(expect.arrayContaining(['gl-hidden', 'md:gl-block']));
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

      it('renders the correct component names', () => {
        expect(findComponentNames().text()).toMatchInterpolatedText(
          '• Components: test-component, component_two',
        );
      });

      it('renders GlTruncate for each component name', () => {
        const names = findComponentNames()
          .findAllComponents(GlTruncate)
          .wrappers.map((x) => x.props('text'));

        expect(names).toEqual(['test-component', 'component_two']);
      });
    });

    describe('when there are lots of components', () => {
      beforeEach(() => {
        // what: Update resource.versions to have at least 5 components
        const versions = update(
          cloneDeep(resource.versions),
          'nodes[0].components.nodes',
          (components) =>
            Array(5)
              .fill(1)
              .map((x, idx) => components[idx % components.length]),
        );

        createComponent({ props: { resource: { ...resource, versions } } });
      });

      it('renders the correct component names with a delimeter', () => {
        expect(findComponentNames().text()).toMatchInterpolatedText(
          '• Components: test-component, component_two, test-component, component_two, test-component',
        );
      });
    });
  });

  describe('project topics', () => {
    describe('when there are no topics', () => {
      it('does not render the topic badges component', () => {
        createComponent();

        expect(findTopicBadgesComponent().exists()).toBe(false);
      });
    });

    describe('when there are topics', () => {
      it('renders the topic badges component', () => {
        const topics = ['vue.js', 'Ruby'];
        createComponent({ props: { resource: { ...resource, topics } } });

        expect(findTopicBadgesComponent().exists()).toBe(true);
        expect(findTopicBadgesComponent().props('topics')).toBe(topics);
      });
    });
  });

  describe('visibility level', () => {
    describe('when the project is public', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render the private icon', () => {
        expect(findVisibilityIcon().exists()).toBe(false);
      });
    });

    describe('when the project is private', () => {
      beforeEach(() => {
        createComponent({
          props: { resource: { ...resource, ...{ visibilityLevel: 'private' } } },
        });
      });

      it('renders the private icon', () => {
        expect(findVisibilityIcon().exists()).toBe(true);
      });
    });
  });

  describe('verification badge', () => {
    describe('when the resource is not verified', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render the verification badge', () => {
        expect(findVerificationBadge().exists()).toBe(false);
      });
    });

    describe.each`
      verificationLevel | describeText
      ${'GITLAB'}       | ${'GitLab'}
      ${'PARTNER'}      | ${'partner'}
    `('when the resource is $describeText maintained', ({ verificationLevel }) => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, verificationLevel } } });
      });

      it('renders the verification badge', () => {
        expect(findVerificationBadge().exists()).toBe(true);
      });

      it('displays the correct badge', () => {
        expect(findVerificationBadge().props('verificationLevel')).toBe(verificationLevel);
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
          path: resource.fullPath,
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
      expect(routerPush).toHaveBeenCalledWith({ path: resource.fullPath });
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
        expect(findFavorites().classes()).toEqual(['!gl-text-inherit']);
      });

      describe('when there are no statistics', () => {
        it('render favorites and usage as 0', () => {
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
        beforeEach(() => {
          createComponent();
        });

        it('render favorites', () => {
          expect(findFavorites().exists()).toBe(true);
          expect(findFavorites().text()).toBe(String(defaultProps.resource.starCount));
        });

        it('render usage data', () => {
          expect(findUsage().exists()).toBe(true);
          expect(findUsage().text()).toBe('4');
        });
      });
    });
  });
});
