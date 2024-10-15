import { GlTooltip, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CanaryIngress from '~/environments/components/canary_ingress.vue';
import DeployBoard from '~/environments/components/deploy_board.vue';
import { deployBoardMockData } from './mock_data';
import { rolloutStatus } from './graphql/mock_data';

describe('Deploy Board', () => {
  let wrapper;

  const createComponent = (props = {}) =>
    mount(DeployBoard, {
      propsData: {
        deployBoardData: deployBoardMockData,
        isLoading: false,
        isEmpty: false,
        ...props,
      },
    });

  describe('with valid data', () => {
    beforeEach(() => {
      wrapper = createComponent();
      return nextTick();
    });

    it('should render percentage with completion value provided', () => {
      expect(wrapper.findComponent({ ref: 'percentage' }).text()).toBe(
        `${deployBoardMockData.completion}%`,
      );
    });

    it('should render total instance count', () => {
      const renderedTotal = wrapper.find('.deploy-board-instances-text');
      const actualTotal = deployBoardMockData.instances.length;
      const output = `${actualTotal > 1 ? 'Instances' : 'Instance'} (${actualTotal})`;

      expect(renderedTotal.text()).toEqual(output);
    });

    it('should render all instances', () => {
      const instances = wrapper.findAll('.deploy-board-instances-container a');

      expect(instances).toHaveLength(deployBoardMockData.instances.length);
      expect(
        instances.at(1).classes(`deployment-instance-${deployBoardMockData.instances[2].status}`),
      ).toBe(true);
    });

    it('should render an abort and a rollback button with the provided url', () => {
      const buttons = wrapper.findAll('.deploy-board-actions a');

      expect(buttons.at(0).attributes('href')).toEqual(deployBoardMockData.rollback_url);
      expect(buttons.at(1).attributes('href')).toEqual(deployBoardMockData.abort_url);
    });

    it('sets up a tooltip for the legend', () => {
      const iconSpan = wrapper.find('[data-testid="legend-tooltip-target"]');
      const tooltip = wrapper.findComponent(GlTooltip);
      const icon = iconSpan.findComponent(GlIcon);

      expect(tooltip.props('target')()).toBe(iconSpan.element);
      expect(icon.props('name')).toBe('question-o');
    });

    it('renders the canary weight selector', () => {
      const canary = wrapper.findComponent(CanaryIngress);
      expect(canary.exists()).toBe(true);
      expect(canary.props('canaryIngress')).toEqual({ canary_weight: 50 });
    });
  });

  describe('with new valid data', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        graphql: true,
        deployBoardData: rolloutStatus,
      });
      await nextTick();
    });

    it('should render percentage with completion value provided', () => {
      expect(wrapper.findComponent({ ref: 'percentage' }).text()).toBe(
        `${rolloutStatus.completion}%`,
      );
    });

    it('should render total instance count', () => {
      const renderedTotal = wrapper.find('.deploy-board-instances-text');
      const actualTotal = rolloutStatus.instances.length;
      const output = `${actualTotal > 1 ? 'Instances' : 'Instance'} (${actualTotal})`;

      expect(renderedTotal.text()).toEqual(output);
    });

    it('should render all instances', () => {
      const instances = wrapper.findAll('.deploy-board-instances-container a');

      expect(instances).toHaveLength(rolloutStatus.instances.length);
      expect(
        instances.at(1).classes(`deployment-instance-${rolloutStatus.instances[2].status}`),
      ).toBe(true);
    });

    it('should render an abort and a rollback button with the provided url', () => {
      const buttons = wrapper.findAll('.deploy-board-actions a');

      expect(buttons.at(0).attributes('href')).toEqual(rolloutStatus.rollbackUrl);
      expect(buttons.at(1).attributes('href')).toEqual(rolloutStatus.abortUrl);
    });

    it('sets up a tooltip for the legend', () => {
      const iconSpan = wrapper.find('[data-testid="legend-tooltip-target"]');
      const tooltip = wrapper.findComponent(GlTooltip);
      const icon = iconSpan.findComponent(GlIcon);

      expect(tooltip.props('target')()).toBe(iconSpan.element);
      expect(icon.props('name')).toBe('question-o');
    });

    it('renders the canary weight selector', () => {
      const canary = wrapper.findComponent(CanaryIngress);
      expect(canary.exists()).toBe(true);
      expect(canary.props('canaryIngress')).toEqual({ canaryWeight: 50 });
      expect(canary.props('graphql')).toBe(true);
    });
  });

  describe('with empty state', () => {
    beforeEach(() => {
      wrapper = createComponent({
        deployBoardData: {},
        isLoading: false,
        isEmpty: true,
      });
      return nextTick();
    });

    it('should render the empty state', () => {
      expect(
        wrapper.find('.deploy-board-empty-state-text .deploy-board-empty-state-title').text(),
      ).toContain('Kubernetes deployment not found');
    });
  });

  describe('with loading state', () => {
    beforeEach(() => {
      wrapper = createComponent({
        deployBoardData: {},
        isLoading: true,
        isEmpty: false,
      });
      return nextTick();
    });

    it('should render loading spinner', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('has legend component', () => {
    let statuses = [];
    beforeEach(() => {
      wrapper = createComponent({
        isLoading: false,
        isEmpty: false,
        deployBoardData: deployBoardMockData,
      });
      ({ statuses } = wrapper.vm);
      return nextTick();
    });

    it('with all the possible statuses', () => {
      const deployBoardLegend = wrapper.find('.deploy-board-legend');

      expect(deployBoardLegend).toBeDefined();
      expect(deployBoardLegend.findAll('a')).toHaveLength(Object.keys(statuses).length);
    });

    Object.keys(statuses).forEach((item) => {
      it(`with ${item} text next to deployment instance icon`, () => {
        expect(wrapper.find(`.deployment-instance-${item}`)).toBeDefined();
        expect(wrapper.find(`.deployment-instance-${item} + .legend-text`).text()).toBe(
          statuses[item].text,
        );
      });
    });
  });
});
