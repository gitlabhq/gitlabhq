import { GlTableLite, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ScanProfileTable from '~/security_configuration/components/scan_profiles/scan_profile_table.vue';
import { SCAN_PROFILE_PROMO_ITEMS } from '~/security_configuration/constants';

describe('ScanProfileTable', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = mountExtended(ScanProfileTable, {
      propsData: {
        tableItems: SCAN_PROFILE_PROMO_ITEMS,
        ...props,
      },
    });

    return wrapper;
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findAllButtons = () => wrapper.findAllComponents(GlButton);
  const findApplyButton = () => findAllButtons().at(0);
  const findPreviewButton = () => findAllButtons().at(1);

  describe('table rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders table with correct fields', () => {
      const table = findTable();
      expect(table.exists()).toBe(true);
      expect(table.props('fields')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ key: 'scanType', label: 'Scanner' }),
          expect.objectContaining({ key: 'name', label: 'Profile' }),
          expect.objectContaining({ key: 'status', label: 'Status' }),
          expect.objectContaining({ key: 'lastScan', label: 'Last scan' }),
          expect.objectContaining({ key: 'actions', label: '' }),
        ]),
      );
    });

    it('passes table items to the table', () => {
      expect(findTable().props('items')).toEqual(SCAN_PROFILE_PROMO_ITEMS);
    });

    it('renders scanner type from promo item', () => {
      expect(wrapper.text()).toContain('SD');
      expect(wrapper.text()).toContain('Secret Detection');
    });

    it('renders "No profile applied"', () => {
      expect(wrapper.text()).toContain('No profile applied');
    });

    it('renders last scan as —', () => {
      expect(wrapper.text()).toContain('—');
    });

    it('renders disabled apply button', () => {
      expect(findApplyButton().props('disabled')).toBe(true);
    });

    it('renders disabled preview button', () => {
      expect(findPreviewButton().props('disabled')).toBe(true);
    });
  });

  describe.each(['name', 'status', 'actions'])('%s slot', (slotName) => {
    it('renders custom status slot content when provided', () => {
      wrapper = mountExtended(ScanProfileTable, {
        propsData: {
          tableItems: SCAN_PROFILE_PROMO_ITEMS,
        },
        scopedSlots: {
          [`cell(${slotName})`]: `<div class="custom-status">Custom ${slotName} content</div>`,
        },
      });

      expect(wrapper.find('.custom-status').exists()).toBe(true);
      expect(wrapper.text()).toContain(`Custom ${slotName} content`);
    });
  });
});
