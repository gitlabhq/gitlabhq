import { GlModal, GlForm, GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemAbuseModal from '~/work_items/components/work_item_abuse_modal.vue';
import { CATEGORY_OPTIONS } from '~/abuse_reports/components/constants';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('WorkItemAbuseModal', () => {
  let wrapper;

  const ACTION_PATH = '/abuse_reports/add_category';
  const USER_ID = 1;
  const REPORTED_FROM_URL = 'http://example.com';

  const createComponent = (props) => {
    wrapper = shallowMountExtended(WorkItemAbuseModal, {
      propsData: {
        reportedUserId: USER_ID,
        reportedFromUrl: REPORTED_FROM_URL,
        ...props,
      },
      provide: {
        reportAbusePath: ACTION_PATH,
      },
    });
  };

  beforeEach(() => {
    createComponent({ showModal: true });
  });

  const findAbuseModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlForm);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  const findCSRFToken = () => findForm().find('input[name="authenticity_token"]');
  const findUserId = () => wrapper.findByTestId('input-user-id');
  const findReferer = () => wrapper.findByTestId('input-referer');

  describe('Modal', () => {
    it('renders report abuse modal with the form', () => {
      expect(findAbuseModal().exists()).toBe(true);
      expect(findForm().exists()).toBe(true);
    });

    it('should set the modal title when the `title` prop is set', () => {
      const title = 'Report abuse to administrator';
      createComponent({ title, showModal: true });

      expect(findAbuseModal().props().title).toBe(title);
    });

    it('should set modal size to `sm` by default', () => {
      expect(findAbuseModal().props('size')).toBe('sm');
    });

    it('renders radio form group with the first option selected by default', () => {
      const firstOption = CATEGORY_OPTIONS[0].value;
      expect(findRadioGroup().attributes('checked')).toBe(firstOption);
    });
  });

  describe('Select category form', () => {
    it('renders POST form with path', () => {
      expect(findForm().attributes()).toMatchObject({
        method: 'post',
        action: ACTION_PATH,
      });
    });

    it('renders csrf token', () => {
      expect(findCSRFToken().attributes('value')).toBe('mock-csrf-token');
    });

    it('renders label', () => {
      expect(findFormGroup().attributes('label')).toBe('Why are you reporting this user?');
    });

    it('renders radio group', () => {
      expect(findRadioGroup().props('options')).toEqual(CATEGORY_OPTIONS);
      expect(findRadioGroup().attributes('name')).toBe('abuse_report[category]');
    });

    it('renders userId as a hidden fields', () => {
      expect(findUserId().attributes()).toMatchObject({
        type: 'hidden',
        name: 'user_id',
        value: USER_ID.toString(),
      });
    });

    it('renders referer as a hidden fields', () => {
      expect(findReferer().attributes()).toMatchObject({
        type: 'hidden',
        name: 'abuse_report[reported_from_url]',
        value: REPORTED_FROM_URL,
      });
    });
  });
});
