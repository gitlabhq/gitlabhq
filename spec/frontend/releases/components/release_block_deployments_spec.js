import { GlButton, GlBadge, GlCollapse, GlTableLite } from '@gitlab/ui';
import ReleaseBlockDeployments from '~/releases/components/release_block_deployments.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import DeploymentTriggerer from '~/environments/environment_details/components/deployment_triggerer.vue';
import Commit from '~/vue_shared/components/commit.vue';
import { mockDeployment } from '../mock_data';

const expectedTableHeaders = [
  'Environment',
  'Status',
  'Deployment ID',
  'Commit',
  'Triggerer',
  'Created',
  'Finished',
];

describe('Release block deployments', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(ReleaseBlockDeployments, {
      propsData: {
        deployments: [mockDeployment],
        ...propsData,
      },
    });
  };

  const findAccordionButton = () => wrapper.findComponent(GlButton);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableHeaders = () => findTable().find('thead').findAll('th');
  const findEnvironmentName = () => wrapper.findByTestId('environment-name');
  const findDeploymentUrl = () => wrapper.findByTestId('deployment-url');
  const findDeploymentStatusLink = () => wrapper.findComponent(DeploymentStatusLink);
  const findDeploymentTriggerer = () => wrapper.findComponent(DeploymentTriggerer);
  const findCommit = () => wrapper.findComponent(Commit);
  const findCreatedAt = () => wrapper.findByTestId('deployment-created-at');
  const findFinishedAt = () => wrapper.findByTestId('deployment-finished-at');

  beforeEach(() => {
    createComponent();
  });

  describe('collapse element', () => {
    it('does exist', () => {
      expect(findCollapse().exists()).toBe(true);
    });
  });

  describe('accordion button', () => {
    it('does exist', () => {
      expect(findAccordionButton().exists()).toBe(true);
    });

    it('has a correct text', () => {
      expect(findAccordionButton().text()).toContain('Deployments');
    });

    it('has a badge element with a deployments count', () => {
      const badge = findBadge();

      expect(badge.exists()).toBe(true);
      expect(badge.text()).toBe('1');
    });

    it('toggles deployments on click', async () => {
      const button = findAccordionButton();
      const collapse = findCollapse();

      expect(collapse.props('visible')).toBe(true);

      await button.trigger('click');
      expect(collapse.props('visible')).toBe(false);

      await button.trigger('click');
      expect(collapse.props('visible')).toBe(true);
    });
  });

  describe('deployments table', () => {
    it('does exist', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders correct column headers', () => {
      const headers = findTableHeaders();

      headers.wrappers.forEach((header, index) => {
        expect(header.text()).toBe(expectedTableHeaders[index]);
      });
    });

    it('renders environment name', () => {
      const element = findEnvironmentName();

      expect(element.exists()).toBe(true);
      expect(element.attributes('href')).toBe(mockDeployment.environment.url);
      expect(element.text()).toBe(mockDeployment.environment.name);
    });

    it('renders deployment status', () => {
      const element = findDeploymentStatusLink();

      expect(element.exists()).toBe(true);
      expect(element.props()).toMatchObject({
        deployment: mockDeployment,
        status: mockDeployment.status,
      });
    });

    it('renders deployment url', () => {
      const element = findDeploymentUrl();

      expect(element.exists()).toBe(true);
      expect(element.attributes('href')).toBe(mockDeployment.deployment.url);
      expect(element.text()).toBe(`${mockDeployment.deployment.id}`);
    });

    it('renders deployment triggerer info', () => {
      const element = findDeploymentTriggerer();

      expect(element.exists()).toBe(true);
      expect(element.props('triggerer')).toMatchObject(mockDeployment.triggerer);
    });

    it('renders commit info', () => {
      const element = findCommit();

      expect(element.exists()).toBe(true);
      expect(element.props()).toMatchObject({
        shortSha: mockDeployment.commit.shortSha,
        commitUrl: mockDeployment.commit.commitUrl,
        title: mockDeployment.commit.title,
        showRefInfo: false,
      });
    });

    it('renders created date', () => {
      const element = findCreatedAt();

      expect(element.exists()).toBe(true);
      expect(element.props()).toMatchObject({
        time: mockDeployment.createdAt,
        enableTruncation: true,
      });
    });

    describe('finished date', () => {
      it('renders when `finishedAt` value is not null', () => {
        const element = findFinishedAt();

        expect(element.exists()).toBe(true);
        expect(element.props()).toMatchObject({
          time: mockDeployment.finishedAt,
          enableTruncation: true,
        });
      });

      it('does not render when `finishedAt` value is null', () => {
        createComponent({ deployments: [{ ...mockDeployment, finishedAt: null }] });

        expect(findFinishedAt().exists()).toBe(false);
      });
    });
  });
});
