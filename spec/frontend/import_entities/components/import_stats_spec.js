import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ImportStats from '~/import_entities/components/import_stats.vue';
import { STATUSES } from '~/import_entities/constants';

describe('Import entities stats component', () => {
  let wrapper;

  const mockStats = {
    labels: {
      fetched: 10,
      imported: 9,
    },
    self: {
      fetched: 1,
      imported: 1,
    },
    milestones: {
      fetched: 1000,
      imported: 999,
    },
    namespace_settings: {
      fetched: 0,
      imported: 0,
    },
  };

  const defaultProps = {
    stats: mockStats,
    status: STATUSES.CREATED,
  };

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(ImportStats, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findAllStatItems = () => wrapper.findAllByTestId('import-stat-item');
  const findGlIcon = (item) => item.findComponent(GlIcon);

  describe('template', () => {
    it('renders items', () => {
      const expectedText = [
        {
          item: 'Label',
          stat: '9/10',
        },
        {
          item: 'Group',
          stat: '1/1',
        },
        {
          item: 'Milestone',
          stat: '999/1000',
        },
        {
          item: 'Namespace setting',
          stat: '0/0',
        },
      ];

      createComponent();

      const items = findAllStatItems();
      expect(items).toHaveLength(Object.keys(mockStats).length);

      items.wrappers.forEach((item, index) => {
        expect(item.text()).toContain(expectedText[index].item);
        expect(item.text()).toContain(expectedText[index].stat);
      });
    });

    describe.each`
      status               | expectedIcons
      ${STATUSES.CREATED}  | ${['running', 'success', 'running', 'scheduled']}
      ${STATUSES.FINISHED} | ${['alert', 'success', 'alert', 'scheduled']}
    `('when status is $status', ({ status, expectedIcons }) => {
      it('renders correct item icons', () => {
        createComponent({
          props: {
            status,
          },
        });

        findAllStatItems().wrappers.forEach((item, index) => {
          expect(findGlIcon(item).props().name).toBe(`status-${expectedIcons[index]}`);
        });
      });
    });
  });
});
