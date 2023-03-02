import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import Title from '~/issues/show/components/title.vue';
import eventHub from '~/issues/show/event_hub';

describe('Title component', () => {
  let wrapper;

  const getTitleHeader = () => wrapper.findByTestId('issue-title');
  const getEditButton = () => wrapper.findComponent(GlButton);

  const createWrapper = (props) => {
    setHTMLFixture(`<title />`);

    wrapper = shallowMountExtended(Title, {
      propsData: {
        issuableRef: '#1',
        titleHtml: 'Testing <img />',
        titleText: 'Testing',
        ...props,
      },
    });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders title HTML', () => {
    createWrapper();

    expect(getTitleHeader().element.innerHTML.trim()).toBe('Testing <img>');
  });

  it('animates title changes', async () => {
    createWrapper();

    await wrapper.setProps({
      titleHtml: 'test',
    });

    expect(getTitleHeader().classes('issue-realtime-pre-pulse')).toBe(true);

    jest.runAllTimers();
    await nextTick();

    expect(getTitleHeader().classes('issue-realtime-trigger-pulse')).toBe(true);
  });

  it('updates page title after changing title', async () => {
    createWrapper();

    await wrapper.setProps({
      titleHtml: 'changed',
      titleText: 'changed',
    });

    expect(document.querySelector('title').textContent.trim()).toContain('changed');
  });

  describe('inline edit button', () => {
    it('should not show by default', () => {
      createWrapper();

      expect(getEditButton().exists()).toBe(false);
    });

    it('should not show if canUpdate is false', () => {
      createWrapper({
        showInlineEditButton: true,
        canUpdate: false,
      });

      expect(getEditButton().exists()).toBe(false);
    });

    it('should show if showInlineEditButton and canUpdate', () => {
      createWrapper({
        showInlineEditButton: true,
        canUpdate: true,
      });

      expect(getEditButton().exists()).toBe(true);
    });

    it('should trigger open.form event when clicked', async () => {
      eventHub.$emit = jest.fn();

      createWrapper({
        showInlineEditButton: true,
        canUpdate: true,
      });

      getEditButton().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('open.form');
    });
  });
});
