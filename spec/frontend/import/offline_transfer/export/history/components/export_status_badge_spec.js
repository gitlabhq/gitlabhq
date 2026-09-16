import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExportStatusBadge from '~/import/offline_transfer/export/history/components/export_status_badge.vue';

describe('OfflineTransferExportStatusBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ExportStatusBadge, {
      propsData: { status: 'created', ...props },
    });
  };

  describe.each`
    status        | text          | variant
    ${'created'}  | ${'Pending'}  | ${'neutral'}
    ${'finished'} | ${'Complete'} | ${'success'}
    ${'failed'}   | ${'Failed'}   | ${'danger'}
  `('when the status is $status', ({ status, text, variant }) => {
    beforeEach(() => {
      createComponent({ props: { status } });
    });

    it(`renders the "${text}" badge`, () => {
      expect(findBadge().text()).toBe(text);
      expect(findBadge().props('variant')).toBe(variant);
    });
  });

  describe('when the export is in progress', () => {
    beforeEach(() => {
      createComponent({ props: { status: 'started' } });
    });

    it('uses export wording', () => {
      expect(findBadge().text()).toBe('Exporting…');
      expect(findBadge().props('variant')).toBe('info');
    });
  });

  describe('when a finished export had failures', () => {
    beforeEach(() => {
      createComponent({ props: { status: 'finished', hasFailures: true } });
    });

    it('renders the partially completed badge', () => {
      expect(findBadge().text()).toBe('Partially completed');
      expect(findBadge().props('variant')).toBe('warning');
    });
  });

  describe('when an unfinished export has failures', () => {
    beforeEach(() => {
      createComponent({ props: { status: 'failed', hasFailures: true } });
    });

    it('does not render the partially completed badge', () => {
      expect(findBadge().text()).toBe('Failed');
      expect(findBadge().props('variant')).toBe('danger');
    });
  });

  describe('when the status is not recognised', () => {
    beforeEach(() => {
      createComponent({ props: { status: 'something_unexpected' } });
    });

    it('renders nothing', () => {
      expect(findBadge().exists()).toBe(false);
    });
  });
});
