import Vue from 'vue';
import DeployBoard from 'ee/environments/components/deploy_board_component.vue';
import { deployBoardMockData, environment } from 'spec/environments/mock_data';

describe('Deploy Board', () => {
  let DeployBoardComponent;

  beforeEach(() => {
    DeployBoardComponent = Vue.extend(DeployBoard);
  });

  describe('with valid data', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: deployBoardMockData,
          isLoading: false,
          isEmpty: false,
          logsPath: environment.log_path,
        },
      }).$mount();
    });

    it('should render percentage with completion value provided', () => {
      expect(
        component.$el.querySelector('.deploy-board-information .percentage').textContent,
      ).toEqual(`${deployBoardMockData.completion}%`);
    });

    it('should render total instance count', () => {
      const renderedTotal = component.$el.querySelector('.deploy-board-instances .total-instances');
      const actualTotal = deployBoardMockData.instances.length;

      expect(
        renderedTotal.textContent,
      ).toEqual(`(${actualTotal})`);
    });

    it('should render all instances', () => {
      const instances = component.$el.querySelectorAll('.deploy-board-instances-container a');

      expect(instances.length).toEqual(deployBoardMockData.instances.length);

      expect(
        instances[2].classList.contains(`deploy-board-instance-${deployBoardMockData.instances[2].status}`),
      ).toBe(true);
    });

    it('should render an abort and a rollback button with the provided url', () => {
      const buttons = component.$el.querySelectorAll('.deploy-board-actions a');

      expect(buttons[0].getAttribute('href')).toEqual(deployBoardMockData.rollback_url);
      expect(buttons[1].getAttribute('href')).toEqual(deployBoardMockData.abort_url);
    });
  });

  describe('with empty state', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: {},
          isLoading: false,
          isEmpty: true,
          logsPath: environment.log_path,
        },
      }).$mount();
    });

    it('should render the empty state', () => {
      expect(component.$el.querySelector('.deploy-board-empty-state-svg svg')).toBeDefined();
      expect(component.$el.querySelector('.deploy-board-empty-state-text .title').textContent).toContain('Kubernetes deployment not found');
    });
  });

  describe('with loading state', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: {},
          isLoading: true,
          isEmpty: false,
          logsPath: environment.log_path,
        },
      }).$mount();
    });

    it('should render loading spinner', () => {
      expect(component.$el.querySelector('.fa-spin')).toBeDefined();
    });
  });
});
