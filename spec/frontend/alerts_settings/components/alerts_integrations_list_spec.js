import { GlTable, GlIcon, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import AlertIntegrationsList, {
  i18n,
} from '~/alerts_settings/components/alerts_integrations_list.vue';
import { trackAlertIntegrationsViewsOptions } from '~/alerts_settings/constants';
import Tracking from '~/tracking';

const mockIntegrations = [
  {
    id: '1',
    active: true,
    name: 'Integration 1',
    type: 'HTTP endpoint',
  },
  {
    id: '2',
    active: false,
    name: 'Integration 2',
    type: 'HTTP endpoint',
  },
];

describe('AlertIntegrationsList', () => {
  let wrapper;
  const { trigger: triggerIntersection } = useMockIntersectionObserver();

  function mountComponent({ data = {}, props = {} } = {}) {
    wrapper = mount(AlertIntegrationsList, {
      data() {
        return { ...data };
      },
      propsData: {
        integrations: mockIntegrations,
        ...props,
      },
      stubs: {
        GlIcon: true,
        GlButton: true,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(() => {
    mountComponent();
  });

  const findTableComponent = () => wrapper.find(GlTable);
  const findTableComponentRows = () => wrapper.find(GlTable).findAll('table tbody tr');
  const finsStatusCell = () => wrapper.findAll('[data-testid="integration-activated-status"]');

  it('renders a table', () => {
    expect(findTableComponent().exists()).toBe(true);
  });

  it('renders an empty state when no integrations provided', () => {
    mountComponent({ props: { integrations: [] } });
    expect(findTableComponent().text()).toContain(i18n.emptyState);
  });

  it('renders an an edit and delete button for each integration', () => {
    expect(findTableComponent().findAll(GlButton).length).toBe(4);
  });

  it('renders an highlighted row when a current integration is selected to edit', () => {
    mountComponent({ data: { currentIntegration: { id: '1' } } });
    expect(findTableComponentRows().at(0).classes()).toContain('gl-bg-blue-50');
  });

  describe('integration status', () => {
    it('enabled', () => {
      const cell = finsStatusCell().at(0);
      const activatedIcon = cell.find(GlIcon);
      expect(cell.text()).toBe(i18n.status.enabled.name);
      expect(activatedIcon.attributes('name')).toBe('check');
      expect(activatedIcon.attributes('title')).toBe(i18n.status.enabled.tooltip);
    });

    it('disabled', () => {
      const cell = finsStatusCell().at(1);
      const notActivatedIcon = cell.find(GlIcon);
      expect(cell.text()).toBe(i18n.status.disabled.name);
      expect(notActivatedIcon.attributes('name')).toBe('warning-solid');
      expect(notActivatedIcon.attributes('title')).toBe(i18n.status.disabled.tooltip);
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      mountComponent();
      jest.spyOn(Tracking, 'event');
    });

    it('should NOT track alert list page views when list is collapsed', () => {
      triggerIntersection(wrapper.vm.$el, { entry: { isIntersecting: false } });

      expect(Tracking.event).not.toHaveBeenCalled();
    });

    it('should track alert list page views only once when list is expanded', () => {
      triggerIntersection(wrapper.vm.$el, { entry: { isIntersecting: true } });
      triggerIntersection(wrapper.vm.$el, { entry: { isIntersecting: true } });
      triggerIntersection(wrapper.vm.$el, { entry: { isIntersecting: true } });

      const { category, action } = trackAlertIntegrationsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledTimes(1);
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});
