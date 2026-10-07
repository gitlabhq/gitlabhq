import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomepageApp from '~/homepage/components/homepage_app.vue';
import PickUpWidget from '~/homepage/components/pick_up_widget.vue';
import PipelinesWidget from '~/homepage/components/pipelines_widget.vue';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';
import TodosWidget from '~/homepage/components/todos_widget.vue';
import ActivityWidget from '~/homepage/components/activity_widget.vue';
import QuickAccessWidget from '~/homepage/components/quick_access_widget.vue';
import { lastPushEvent } from './mocks/last_push_event_mock';

describe('HomepageApp', () => {
  const MOCK_ACTIVITY_PATH = '/activity/path';

  let wrapper;

  const findPickUpWidget = () => wrapper.findComponent(PickUpWidget);
  const findPipelinesWidget = () => wrapper.findComponent(PipelinesWidget);
  const findMergeRequestsWidget = () => wrapper.findComponent(MergeRequestsWidget);
  const findTodosWidget = () => wrapper.findComponent(TodosWidget);
  const findActivityWidget = () => wrapper.findComponent(ActivityWidget);
  const findQuickAccessWidget = () => wrapper.findComponent(QuickAccessWidget);

  function createWrapper(props = {}, { glFeatures = { homepagePipelinesWidget: true } } = {}) {
    wrapper = shallowMountExtended(HomepageApp, {
      provide: { glFeatures },
      propsData: {
        activityPath: MOCK_ACTIVITY_PATH,
        lastPushEvent,
        ...props,
      },
    });
  }

  beforeEach(() => {
    createWrapper();
  });

  it('renders the widgets that are always present', () => {
    expect(findTodosWidget().exists()).toBe(true);
    expect(findActivityWidget().exists()).toBe(true);
    expect(findQuickAccessWidget().exists()).toBe(true);
  });

  it('passes the activity path to the ActivityWidget component', () => {
    expect(findActivityWidget().props('activityPath')).toBe(MOCK_ACTIVITY_PATH);
  });

  it('renders the MergeRequestsWidget component unconditionally', () => {
    expect(findMergeRequestsWidget().exists()).toBe(true);
  });

  it('passes the correct props to the `PickUpWidget` component', () => {
    expect(findPickUpWidget().props()).toEqual({
      lastPushEvent,
    });
  });

  it('renders the PickUpWidget component', () => {
    expect(findPickUpWidget().exists()).toBe(true);
  });

  it('renders the PipelinesWidget component when the homepage_pipelines_widget flag is enabled', () => {
    expect(findPipelinesWidget().exists()).toBe(true);
  });

  describe('when the homepage_pipelines_widget flag is disabled', () => {
    it('does not render the PipelinesWidget component', () => {
      createWrapper({}, { glFeatures: { homepagePipelinesWidget: false } });

      expect(findPipelinesWidget().exists()).toBe(false);
    });
  });

  describe('when there is no lastPushEvent', () => {
    it('does not render the PickUpWidget component', () => {
      createWrapper({
        lastPushEvent: null,
      });
      expect(findPickUpWidget().exists()).toBe(false);
    });
  });

  describe('when there is no create_mr_path', () => {
    it('does not render the PickUpWidget component', () => {
      createWrapper({
        lastPushEvent: { ...lastPushEvent, create_mr_path: null },
      });
      expect(findPickUpWidget().exists()).toBe(false);
    });
  });

  describe('when lastPushEvent.show_widget is false but there is valid push event data', () => {
    it('shows the widget', () => {
      createWrapper({ lastPushEvent: { ...lastPushEvent, show_widget: false } });

      expect(findPickUpWidget().exists()).toBe(true);
    });
  });
});
