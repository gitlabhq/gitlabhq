import mockDeploymentFixture from 'test_fixtures/graphql/deployments/graphql/queries/deployment.query.graphql.json';
import mockEnvironmentFixture from 'test_fixtures/graphql/deployments/graphql/queries/environment.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ShowMore from '~/vue_shared/components/show_more.vue';
import DeploymentAside from '~/deployments/components/deployment_aside.vue';

const {
  data: {
    project: { deployment },
  },
} = mockDeploymentFixture;
const {
  data: {
    project: { environment },
  },
} = mockEnvironmentFixture;

describe('~/deployments/components/deployment_header.vue', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(DeploymentAside, {
      propsData: {
        deployment,
        environment,
        loading: false,
        ...propsData,
      },
    });
  };

  describe('loading', () => {
    it('hides everything', () => {
      createComponent({ propsData: { loading: true } });

      expect(wrapper.find('aside').exists()).toBe(false);
    });
  });

  describe('with all properties', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a link to the external url', () => {
      const link = wrapper.findByRole('link', { name: 'Open URL' });

      expect(link.attributes('href')).toBe(environment.externalUrl);
    });

    it('shows a link to the triggerer', () => {
      const link = wrapper.findByTestId('deployment-triggerer');

      expect(link.attributes('href')).toBe(deployment.triggerer.webUrl);
      expect(link.text()).toContain(deployment.triggerer.name);
    });

    it('shows a link to the tags of a deployment', () => {
      deployment.tags.forEach((tag) => {
        const link = wrapper.findByRole('link', { name: tag.name });

        expect(link.attributes('href')).toBe(tag.path);
      });
    });

    it('links to the deployment ref', () => {
      const link = wrapper.findByRole('link', { name: deployment.ref });

      expect(link.attributes('href')).toBe(deployment.refPath);
    });

    it('displays if the ref is a branch', () => {
      const ref = wrapper.findByTestId('deployment-ref');

      expect(ref.find('span').text()).toBe('Branch');
    });
  });

  describe('without optional properties', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            tags: [],
            job: null,
            tag: true,
          },
          environment: {
            ...environment,
            externalUrl: '',
          },
        },
      });
    });

    it('does not show a link to the external url', () => {
      const link = wrapper.findByRole('link', { name: 'Open URL' });

      expect(link.exists()).toBe(false);
    });

    it('does not show a link to the tags of a deployment', () => {
      const showMore = wrapper.findComponent(ShowMore);

      expect(showMore.exists()).toBe(false);
    });

    it('displays if the ref is a branch', () => {
      const ref = wrapper.findByTestId('deployment-ref');

      expect(ref.find('span').text()).toBe('Tag');
    });
  });
});
