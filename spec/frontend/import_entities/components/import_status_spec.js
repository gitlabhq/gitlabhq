import { GlAccordionItem, GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ImportStatus from '~/import_entities/components/import_status.vue';
import { STATUSES } from '~/import_entities/constants';

describe('Import entities status component', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(ImportStatus, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('success status', () => {
    const getStatusText = () => wrapper.findComponent(GlBadge).text();
    const getStatusIcon = () => wrapper.findComponent(GlBadge).props('icon');

    it('displays finished status as complete when no stats are provided', () => {
      createComponent({
        status: STATUSES.FINISHED,
      });
      expect(getStatusText()).toBe('Complete');
    });

    it('displays finished status as complete when all stats items were processed', () => {
      const statItems = { label: 100, note: 200 };

      createComponent({
        status: STATUSES.FINISHED,
        stats: {
          fetched: { ...statItems },
          imported: { ...statItems },
        },
      });

      expect(getStatusText()).toBe('Complete');
      expect(getStatusIcon()).toBe('status-success');
    });

    it('displays finished status as partial when all stats items were processed', () => {
      const statItems = { label: 100, note: 200 };

      createComponent({
        status: STATUSES.FINISHED,
        stats: {
          fetched: { ...statItems },
          imported: { ...statItems, label: 50 },
        },
      });

      expect(getStatusText()).toBe('Partial import');
      expect(getStatusIcon()).toBe('status-alert');
    });
  });

  describe('details drawer', () => {
    const findDetailsDrawer = () => wrapper.findComponent(GlAccordionItem);

    it('renders details drawer to be present when stats are provided', () => {
      createComponent({
        status: 'created',
        stats: { fetched: { label: 1 }, imported: { label: 0 } },
      });

      expect(findDetailsDrawer().exists()).toBe(true);
    });

    it('does not render details drawer when no stats are provided', () => {
      createComponent({
        status: 'created',
      });

      expect(findDetailsDrawer().exists()).toBe(false);
    });

    it('does not render details drawer when stats are empty', () => {
      createComponent({
        status: 'created',
        stats: { fetched: {}, imported: {} },
      });

      expect(findDetailsDrawer().exists()).toBe(false);
    });

    it('does not render details drawer when no known stats are provided', () => {
      createComponent({
        status: 'created',
        stats: {
          fetched: {
            UNKNOWN_STAT: 100,
          },
          imported: {
            UNKNOWN_STAT: 0,
          },
        },
      });

      expect(findDetailsDrawer().exists()).toBe(false);
    });
  });

  describe('stats display', () => {
    const getStatusIcon = () =>
      wrapper.findComponent(GlAccordionItem).findComponent(GlIcon).props().name;

    const createComponentWithStats = ({ fetched, imported, status = 'created' }) => {
      createComponent({
        status,
        stats: {
          fetched: { label: fetched },
          imported: { label: imported },
        },
      });
    };

    it('displays scheduled status when imported is 0', () => {
      createComponentWithStats({
        fetched: 100,
        imported: 0,
      });

      expect(getStatusIcon()).toBe('status-scheduled');
    });

    it('displays running status when imported is not equal to fetched and import is not finished', () => {
      createComponentWithStats({
        fetched: 100,
        imported: 10,
      });

      expect(getStatusIcon()).toBe('status-running');
    });

    it('displays alert status when imported is not equal to fetched and import is finished', () => {
      createComponentWithStats({
        fetched: 100,
        imported: 10,
        status: STATUSES.FINISHED,
      });

      expect(getStatusIcon()).toBe('status-alert');
    });

    it('displays success status when imported is equal to fetched', () => {
      createComponentWithStats({
        fetched: 100,
        imported: 100,
      });

      expect(getStatusIcon()).toBe('status-success');
    });
  });
});
