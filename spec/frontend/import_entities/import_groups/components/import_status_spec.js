import { GlBadge, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ImportStatus from '~/import_entities/import_groups/components/import_status.vue';
import { STATUSES, STATUS_ICON_MAP } from '~/import_entities/constants';

describe('Group import status component', () => {
  let wrapper;

  const defaultProps = {
    status: STATUSES.FINISHED,
  };

  const mockDetailsPath = '/:id/failures/:entity_id';

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(ImportStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        detailsPath: mockDetailsPath,
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe('status badge text', () => {
    describe('when import is partial', () => {
      beforeEach(() => {
        createComponent({
          props: {
            status: STATUSES.FINISHED,
            hasFailures: true,
          },
        });
      });

      it('renders warning badge with text', () => {
        expect(findGlBadge().props()).toMatchObject({
          icon: 'status-alert',
          variant: 'warning',
        });
        expect(findGlBadge().text()).toBe('Partially completed');
      });
    });

    describe.each([
      STATUSES.CREATED,
      STATUSES.FAILED,
      STATUSES.FINISHED,
      STATUSES.STARTED,
      STATUSES.TIMEOUT,
    ])(`when import is %s`, (status) => {
      beforeEach(() => {
        createComponent({
          props: {
            status,
          },
        });
      });

      it('renders badge with text', () => {
        const expectedStatus = STATUS_ICON_MAP[status];

        expect(findGlBadge().props()).toMatchObject({
          icon: expectedStatus.icon,
          variant: expectedStatus.variant,
        });
        expect(findGlBadge().text()).toBe(expectedStatus.text);
      });
    });
  });

  describe('details link', () => {
    it('does not render by default', () => {
      createComponent();

      expect(findGlLink().exists()).toBe(false);
    });

    it('renders with correct link when import is partial', () => {
      createComponent({
        props: {
          id: 2,
          entityId: 11,
          hasFailures: true,
          status: STATUSES.FINISHED,
        },
      });

      expect(findGlLink().attributes('href')).toBe('/2/failures/11');
    });
  });
});
