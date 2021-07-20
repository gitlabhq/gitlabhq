<script>
import { INFINITELY_NESTED_COLLAPSIBLE_SECTIONS_FF } from '../../constants';

export default {
  functional: true,
  props: {
    lineNumber: {
      type: Number,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  render(h, { props }) {
    const { lineNumber, path } = props;

    const parsedLineNumber = gon.features?.[INFINITELY_NESTED_COLLAPSIBLE_SECTIONS_FF]
      ? lineNumber
      : lineNumber + 1;
    const lineId = `L${parsedLineNumber}`;
    const lineHref = `${path}#${lineId}`;

    return h(
      'a',
      {
        class: 'gl-link d-inline-block text-right line-number flex-shrink-0',
        attrs: {
          id: lineId,
          href: lineHref,
        },
      },
      parsedLineNumber,
    );
  },
};
</script>
