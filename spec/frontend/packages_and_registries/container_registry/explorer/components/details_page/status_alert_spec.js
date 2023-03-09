import { GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/status_alert.vue';
import {
  DELETE_SCHEDULED,
  DELETE_FAILED,
  PACKAGE_DELETE_HELP_PAGE_PATH,
  SCHEDULED_FOR_DELETION_STATUS_TITLE,
  SCHEDULED_FOR_DELETION_STATUS_MESSAGE,
  FAILED_DELETION_STATUS_TITLE,
  FAILED_DELETION_STATUS_MESSAGE,
} from '~/packages_and_registries/container_registry/explorer/constants';

describe('Status Alert', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findMessage = () => wrapper.find('[data-testid="message"]');

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  it.each`
    status              | title                                  | variant      | message                                  | link
    ${DELETE_SCHEDULED} | ${SCHEDULED_FOR_DELETION_STATUS_TITLE} | ${'info'}    | ${SCHEDULED_FOR_DELETION_STATUS_MESSAGE} | ${PACKAGE_DELETE_HELP_PAGE_PATH}
    ${DELETE_FAILED}    | ${FAILED_DELETION_STATUS_TITLE}        | ${'warning'} | ${FAILED_DELETION_STATUS_MESSAGE}        | ${''}
  `(
    `when the status is $status, title is $title, variant is $variant, message is $message and the link is $link`,
    ({ status, title, variant, message, link }) => {
      mountComponent({ status });

      expect(findMessage().text()).toMatchInterpolatedText(message);
      expect(findAlert().props()).toMatchObject({
        title,
        variant,
      });
      if (link) {
        expect(findLink().attributes()).toMatchObject({
          target: '_blank',
          href: link,
        });
      }
    },
  );
});
