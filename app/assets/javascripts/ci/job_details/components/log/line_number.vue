<script>
export default {
  name: 'LineNumber',
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
        class: 'job-log-line-number',
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
