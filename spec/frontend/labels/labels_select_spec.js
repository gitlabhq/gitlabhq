import $ from 'jquery';
import LabelsSelect from '~/labels/labels_select';

const mockUrl = '/foo/bar/url';

const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
];

const mockScopedLabels = [
  {
    id: 27,
    title: 'Foo::Bar',
    description: 'Foobar',
    color: '#333ABC',
    text_color: '#FFFFFF',
  },
];

const mockScopedLabels2 = [
  {
    id: 28,
    title: 'Foo::Bar2',
    description: 'Foobar2',
    color: '#FFFFFF',
    text_color: '#333333',
  },
];

describe('LabelsSelect', () => {
  describe('getLabelTemplate', () => {
    describe('when normal label is present', () => {
      const label = mockLabels[0];
      let $labelEl;

      beforeEach(() => {
        $labelEl = $(
          LabelsSelect.getLabelTemplate({
            labels: mockLabels,
            issueUpdateURL: mockUrl,
            enableScopedLabels: true,
          }),
        );
      });

      it('generated label item template has correct label URL', () => {
        expect($labelEl.find('a').attr('href')).toBe('/foo/bar?label_name[]=Foo%20Label');
      });

      it('generated label item template has correct label title', () => {
        expect($labelEl.find('span.gl-label-text').text()).toBe(label.title);
      });

      it('generated label item template has label description as title attribute', () => {
        expect($labelEl.find('a').attr('title')).toBe(label.description);
      });

      it('generated label item template has correct label styles and classes', () => {
        expect($labelEl.find('span.gl-label-text').attr('style')).toBe(
          `background-color: ${label.color};`,
        );
        expect($labelEl.find('span.gl-label-text')).toHaveClass('gl-label-text-light');
      });

      it('generated label item has a gl-label-text class', () => {
        expect($labelEl.find('span').hasClass('gl-label-text')).toEqual(true);
      });
    });

    describe('when scoped label is present', () => {
      const label = mockScopedLabels[0];
      let $labelEl;

      beforeEach(() => {
        $labelEl = $(
          LabelsSelect.getLabelTemplate({
            labels: mockScopedLabels,
            issueUpdateURL: mockUrl,
            enableScopedLabels: true,
          }),
        );
      });

      it('generated label item template has correct label URL', () => {
        expect($labelEl.find('a').attr('href')).toBe('/foo/bar?label_name[]=Foo%3A%3ABar');
      });

      it('generated label item template has correct label title', () => {
        const scopedTitle = label.title.split('::');
        expect($labelEl.find('span.gl-label-text').text()).toContain(scopedTitle[0]);
        expect($labelEl.find('span.gl-label-text').text()).toContain(scopedTitle[1]);
      });

      it('generated label item template has html flag as true', () => {
        expect($labelEl.find('a').attr('data-html')).toBe('true');
      });

      it('generated label item template has correct title for tooltip', () => {
        expect($labelEl.find('a').attr('title')).toBe(
          "<span class='font-weight-bold'>Scoped label</span><br>Foobar",
        );
      });

      it('generated label item template has correct label styles and classes', () => {
        expect($labelEl.find('span.gl-label-text').attr('style')).toBe(
          `background-color: ${label.color};`,
        );
        expect($labelEl.find('span.gl-label-text')).toHaveClass('gl-label-text-light');
        expect($labelEl.find('span.gl-label-text').last()).not.toHaveClass('gl-label-text-light');
      });

      it('generated label item has a badge class', () => {
        expect($labelEl.find('span').hasClass('gl-label-text')).toEqual(true);
      });
    });

    describe('when scoped label is present, with text color not white', () => {
      const label = mockScopedLabels2[0];
      let $labelEl;

      beforeEach(() => {
        $labelEl = $(
          LabelsSelect.getLabelTemplate({
            labels: mockScopedLabels2,
            issueUpdateURL: mockUrl,
            enableScopedLabels: true,
          }),
        );
      });

      it('generated label item template has correct label styles and classes', () => {
        expect($labelEl.find('span.gl-label-text').attr('style')).toBe(
          `background-color: ${label.color};`,
        );
        expect($labelEl.find('span.gl-label-text')).toHaveClass('gl-label-text-dark');
        expect($labelEl.find('span.gl-label-text').last()).toHaveClass('gl-label-text-dark');
      });
    });
  });
});
