import { nextTick } from 'vue';
import { GlPagination, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReviewExportTab from '~/import/offline_transfer/export/review_export_tab.vue';
import GroupRow from '~/import/offline_transfer/components/group_row.vue';

describe('ReviewExportTab', () => {
  let wrapper;

  const bucketName = 'my<bucket';

  const createGroups = (count) =>
    Array.from({ length: count }, (_, index) => ({
      id: `gid://glab/Group/${index + 1}`,
      fullName: `Group ${index + 1}`,
      description: `Description ${index + 1}`,
      avatarUrl: `/avatar/${index + 1}.png`,
    }));

  const createComponent = (selectedGroups, props = {}) => {
    wrapper = shallowMountExtended(ReviewExportTab, {
      propsData: { selectedGroups, bucketName, ...props },
      stubs: { GlSprintf },
    });
  };

  const findGroupRows = () => wrapper.findAllComponents(GroupRow);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findReviewExportText = () => wrapper.findByTestId('review-text');
  const findSubmitError = () => wrapper.findComponentByTestId('submit-error');
  const findSuccessPanel = () => wrapper.findByTestId('submit-success');
  const findViewExportStatusButton = () => wrapper.findByTestId('view-export-status-button');

  describe('when groups list fits on one page', () => {
    const groups = createGroups(1);

    beforeEach(() => {
      createComponent(groups);
    });

    it('renders a static row for every selected group', () => {
      expect(findGroupRows().at(0).props('selectable')).toBe(false);
      expect(findGroupRows()).toHaveLength(1);
    });

    it('passes the group details to each row', () => {
      expect(findGroupRows().at(0).props()).toMatchObject({
        name: groups[0].fullName,
        description: groups[0].description,
        avatarUrl: groups[0].avatarUrl,
      });
    });

    it('shows the correct group count and bucket name', () => {
      expect(findReviewExportText().text()).toBe(
        `1 group will be exported to ${bucketName}. Select Start export to confirm.`,
      );
    });

    it('does not render pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('when group count exceeds one page', () => {
    const groups = createGroups(23);

    beforeEach(() => {
      createComponent(groups);
    });

    it('shows the correct group count', () => {
      expect(findReviewExportText().text()).toBe(
        `23 groups will be exported to ${bucketName}. Select Start export to confirm.`,
      );
    });

    it('shows only the first ten rows', () => {
      expect(findGroupRows()).toHaveLength(10);
      expect(findGroupRows().at(0).props('name')).toBe('Group 1');
      expect(findGroupRows().at(9).props('name')).toBe('Group 10');
    });

    it('passes pagination controls correctly', () => {
      expect(findPagination().props()).toMatchObject({
        value: 1,
        perPage: 10,
        totalItems: 23,
      });
    });

    it('shows the correct groups after the page changes', async () => {
      findPagination().vm.$emit('input', 2);
      await nextTick();

      expect(findGroupRows()).toHaveLength(10);
      expect(findGroupRows().at(0).props('name')).toBe('Group 11');
      expect(findPagination().props('value')).toBe(2);
    });

    it('shows the remaining rows on the last page', async () => {
      findPagination().vm.$emit('input', 3);
      await nextTick();

      expect(findGroupRows()).toHaveLength(3);
      expect(findGroupRows().at(0).props('name')).toBe('Group 21');
    });

    it('resets pagination to the first page when selected groups prop changes', async () => {
      findPagination().vm.$emit('input', 3);
      await nextTick();
      expect(findPagination().props('value')).toBe(3);

      await wrapper.setProps({ selectedGroups: createGroups(15) });

      expect(findPagination().props('value')).toBe(1);
    });
  });

  describe('when Offline Export submission fails', () => {
    const submissionError = 'Unable to access object storage bucket.';

    beforeEach(() => {
      createComponent(createGroups(2), { submissionError });
    });

    it('renders a non-dismissible danger alert with the error message', () => {
      const alert = findSubmitError();

      expect(findSuccessPanel().exists()).toBe(false);
      expect(alert.props()).toMatchObject({
        title: 'Export failed',
        variant: 'danger',
        dismissible: false,
      });
      expect(alert.text()).toBe(submissionError);
    });

    it('hides the review subheader text', () => {
      expect(findReviewExportText().exists()).toBe(false);
    });

    it('keeps the selected groups list visible', () => {
      expect(findGroupRows()).toHaveLength(2);
    });
  });

  describe('when Offline Export submission succeeds', () => {
    beforeEach(() => {
      createComponent(createGroups(2), { hasSubmitSucceeded: true });
    });

    it('renders the success panel', () => {
      expect(findSuccessPanel().text()).toContain('Export started');
      expect(findSuccessPanel().text()).toContain(
        `You can leave this page. We'll email you when the export of 2 groups is finished and the package is ready in bucket ${bucketName}.`,
      );
      expect(findReviewExportText().exists()).toBe(false);
      expect(findGroupRows()).toHaveLength(0);
      expect(findSubmitError().exists()).toBe(false);
    });

    it('links the view export status button to the export history page', () => {
      expect(findViewExportStatusButton().attributes('href')).toBe(
        '/import/offline/export/history',
      );
      expect(findViewExportStatusButton().text()).toBe('View export status');
    });
  });
});
