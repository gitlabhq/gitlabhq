import { shallowMount, mount } from '@vue/test-utils';
import Line from '~/ci/job_details/components/log/line.vue';
import LineNumber from '~/ci/job_details/components/log/line_number.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

const httpUrl = 'http://example.com';
const httpsUrl = 'https://example.com';
const queryUrl = 'https://example.com?param=val';

const mockProps = ({ text = 'Running with gitlab-runner 12.1.0 (de7731dd)' } = {}) => ({
  line: {
    content: [
      {
        text,
        style: 'term-fg-l-green',
      },
    ],
    lineNumber: 0,
  },
  path: '/jashkenas/underscore/-/jobs/335',
});

describe('Job Log Line', () => {
  let wrapper;
  let data;

  const createComponent = (props, mountFn = shallowMount) => {
    wrapper = mountFn(Line, {
      propsData: {
        path: '/',
        ...props,
      },
    });
  };

  const findLine = () => wrapper.find('span');
  const findLink = () => findLine().find('a');
  const findLinks = () => findLine().findAll('a');
  const findLinkAttributeByIndex = (i) => findLinks().at(i).attributes();

  beforeEach(() => {
    data = mockProps();
    createComponent(data);
  });

  it('renders the line number component', () => {
    expect(wrapper.findComponent(LineNumber).exists()).toBe(true);
  });

  it('renders a span with provided text', () => {
    expect(findLine().text()).toBe(data.line.content[0].text);
  });

  it('renders a span with multiple parts of text', () => {
    createComponent({
      line: {
        content: [
          { text: 'A line that ', style: 'style-1' },
          { text: 'continues.', style: 'style-2' },
        ],
        lineNumber: 0,
      },
    });

    expect(findLine().text()).toBe('A line that continues.');
    expect(findLine().element.innerHTML).toBe(
      '<span class="style-1">A line that </span><span class="style-2">continues.</span>',
    );
  });

  it('renders the provided style as a class attribute', () => {
    expect(findLine().find(`.${data.line.content[0].style}`).exists()).toBe(true);
  });

  describe('job urls as links', () => {
    it('renders an http link', () => {
      createComponent(mockProps({ text: httpUrl }));

      expect(findLink().text()).toBe(httpUrl);
      expect(findLink().attributes().href).toBe(httpUrl);
    });

    it('renders an https link', () => {
      createComponent(mockProps({ text: httpsUrl }));

      expect(findLink().text()).toBe(httpsUrl);
      expect(findLink().attributes().href).toBe(httpsUrl);
    });

    it('renders a link with rel nofollow and noopener', () => {
      createComponent(mockProps({ text: httpsUrl }));

      expect(findLink().attributes().rel).toBe('nofollow noopener noreferrer');
    });

    it('renders a link with corresponding styles', () => {
      createComponent(mockProps({ text: httpsUrl }));

      expect(findLink().classes()).toEqual(['!gl-text-inherit', 'gl-underline']);
    });

    it('renders links with queries, surrounded by questions marks', () => {
      createComponent(mockProps({ text: `Did you see my url ${queryUrl}??` }));

      expect(findLine().text()).toBe('Did you see my url https://example.com?param=val??');
      expect(findLinkAttributeByIndex(0).href).toBe(queryUrl);
    });

    it('renders links with queries, surrounded by exclamation marks', () => {
      createComponent(mockProps({ text: `No! The ${queryUrl}!?` }));

      expect(findLine().text()).toBe('No! The https://example.com?param=val!?');
      expect(findLinkAttributeByIndex(0).href).toBe(queryUrl);
    });

    it('renders links that have brackets `[]` in their parameters', () => {
      const url = `${httpUrl}?label_name[]=frontend`;

      createComponent(mockProps({ text: url }));

      expect(findLine().text()).toBe(url);
      expect(findLinks().at(0).text()).toBe(url);
      expect(findLinks().at(0).attributes('href')).toBe(url);
    });

    it('renders links surrounded by brackets `[]`', () => {
      const url = `[${httpUrl}]`;

      createComponent(mockProps({ text: url }));

      expect(findLine().text()).toBe(url);
      expect(findLinks().at(0).text()).toBe(httpUrl);
      expect(findLinks().at(0).attributes('href')).toBe(httpUrl);
    });

    it('renders multiple links surrounded by text', () => {
      createComponent(
        mockProps({ text: `Well, my HTTP url: ${httpUrl} and my HTTPS url: ${httpsUrl}` }),
      );
      expect(findLine().text()).toBe(
        'Well, my HTTP url: http://example.com and my HTTPS url: https://example.com',
      );

      expect(findLinks()).toHaveLength(2);

      expect(findLinkAttributeByIndex(0).href).toBe(httpUrl);
      expect(findLinkAttributeByIndex(1).href).toBe(httpsUrl);
    });

    it('renders multiple links surrounded by text, with other symbols', () => {
      createComponent(
        mockProps({ text: `${httpUrl}, ${httpUrl}: ${httpsUrl}; ${httpsUrl}. ${httpsUrl}...` }),
      );
      expect(findLine().text()).toBe(
        'http://example.com, http://example.com: https://example.com; https://example.com. https://example.com...',
      );

      expect(findLinks()).toHaveLength(5);

      expect(findLinkAttributeByIndex(0).href).toBe(httpUrl);
      expect(findLinkAttributeByIndex(1).href).toBe(httpUrl);
      expect(findLinkAttributeByIndex(2).href).toBe(httpsUrl);
      expect(findLinkAttributeByIndex(3).href).toBe(httpsUrl);
      expect(findLinkAttributeByIndex(4).href).toBe(httpsUrl);
    });

    it('renders multiple links surrounded by brackets', () => {
      createComponent(mockProps({ text: `(${httpUrl}) <${httpUrl}> {${httpsUrl}}` }));
      expect(findLine().text()).toBe(
        '(http://example.com) <http://example.com> {https://example.com}',
      );

      const links = findLinks();

      expect(links).toHaveLength(3);

      expect(links.at(0).text()).toBe(httpUrl);
      expect(links.at(0).attributes('href')).toBe(httpUrl);

      expect(links.at(1).text()).toBe(httpUrl);
      expect(links.at(1).attributes('href')).toBe(httpUrl);

      expect(links.at(2).text()).toBe(httpsUrl);
      expect(links.at(2).attributes('href')).toBe(httpsUrl);
    });

    it('renders text with symbols in it', () => {
      const text = 'apt-get update < /dev/null > /dev/null';
      createComponent(mockProps({ text }));

      expect(findLine().text()).toBe(text);
    });

    const jshref = 'javascript:doEvil();'; // eslint-disable-line no-script-url

    it.each`
      type             | text
      ${'html link'}   | ${'<a href="#">linked</a>'}
      ${'html script'} | ${'<script>doEvil();</script>'}
      ${'html strong'} | ${'<strong>highlighted</strong>'}
      ${'js'}          | ${jshref}
      ${'file'}        | ${'file:///a-file'}
      ${'ftp'}         | ${'ftp://example.com/file'}
      ${'email'}       | ${'email@example.com'}
      ${'no scheme'}   | ${'example.com/page'}
    `('does not render a $type link', ({ text }) => {
      createComponent(mockProps({ text }));
      expect(findLink().exists()).toBe(false);
    });
  });

  describe('job line time', () => {
    it('shows a time', () => {
      const lineNumber = 1;
      const time = '00:00:01Z';
      const text = 'text';

      createComponent(
        {
          line: {
            time,
            content: [{ text }],
            lineNumber,
          },
          path: '/',
        },
        mount,
      );

      expect(wrapper.text()).toBe(`${lineNumber}${time}${text}`);
    });
  });

  describe('job log search', () => {
    it('applies highlight class to search result elements', () => {
      createComponent({
        line: {
          offset: 1560,
          content: [{ text: '82.71' }],
          section: 'step-script',
          lineNumber: 21,
        },
        path: '/root/ci-project/-/jobs/1089',
        isHighlighted: true,
      });

      expect(wrapper.classes()).toContain('job-log-line-highlight');
    });

    it('does not apply highlight class to search result elements', () => {
      createComponent({
        line: {
          offset: 1560,
          content: [{ text: 'docker' }],
          section: 'step-script',
          lineNumber: 29,
        },
        path: '/root/ci-project/-/jobs/1089',
      });

      expect(wrapper.classes()).not.toContain('job-log-line-highlight');
    });
  });

  describe('job log hash highlighting', () => {
    describe('with hash', () => {
      beforeEach(() => {
        setWindowLocation(`http://foo.com/root/ci-project/-/jobs/6353#L77`);
      });

      it('applies highlight class to job log line', () => {
        createComponent({
          line: {
            offset: 24526,
            content: [{ text: 'job log content' }],
            section: 'custom-section',
            lineNumber: 77,
          },
          path: '/root/ci-project/-/jobs/6353',
        });

        expect(wrapper.classes()).toContain('job-log-line-highlight');
      });
    });

    describe('without hash', () => {
      beforeEach(() => {
        setWindowLocation(`http://foo.com/root/ci-project/-/jobs/6353`);
      });

      it('does not apply highlight class to job log line', () => {
        createComponent({
          line: {
            offset: 24500,
            content: [{ text: 'line' }],
            section: 'custom-section',
            lineNumber: 10,
          },
          path: '/root/ci-project/-/jobs/6353',
        });

        expect(wrapper.classes()).not.toContain('job-log-line-highlight');
      });
    });
  });
});
