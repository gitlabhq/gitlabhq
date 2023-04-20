import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import DynamicContent from '~/vue_merge_request_widget/components/widget/dynamic_content.vue';
import ContentRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';

describe('~/vue_merge_request_widget/components/widget/dynamic_content.vue', () => {
  let wrapper;

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(DynamicContent, {
      propsData: {
        widgetName: 'MyWidget',
        ...propsData,
      },
      stubs: {
        DynamicContent,
        ContentRow,
      },
    });
  };

  it('renders given data', () => {
    createComponent({
      propsData: {
        data: {
          id: 'row-id',
          header: ['This is a header', 'This is a subheader'],
          text: 'Main text for the row',
          subtext: 'Optional: Smaller sub-text to be displayed below the main text',
          helpPopover: {
            options: { title: 'Widget help popover title' },
            content: { text: 'Widget help popover content' },
          },
          icon: {
            name: EXTENSION_ICONS.success,
          },
          badge: {
            text: 'Badge is optional. Text to be displayed inside badge',
            variant: 'info',
          },
          link: {
            text: 'Optional link to display after text',
            href: 'https://gitlab.com',
          },
          children: [
            {
              id: 'row-id-2',
              header: 'Child row header',
              text: 'This is recursive. It will be listed in level 3.',
            },
          ],
        },
      },
    });

    expect(wrapper.html()).toMatchSnapshot();
  });
});
