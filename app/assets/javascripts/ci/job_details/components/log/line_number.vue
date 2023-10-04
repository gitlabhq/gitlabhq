<script>
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

    const lineId = `L${lineNumber}`;
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
      lineNumber,
    );
  },
};
</script>
