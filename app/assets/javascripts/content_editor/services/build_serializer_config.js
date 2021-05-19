const buildSerializerConfig = (extensions = []) =>
  extensions
    .filter(({ serializer }) => serializer)
    .reduce(
      (serializers, { serializer, tiptapExtension: { name, type } }) => {
        const collection = `${type}s`;

        return {
          ...serializers,
          [collection]: {
            ...serializers[collection],
            [name]: serializer,
          },
        };
      },
      {
        nodes: {},
        marks: {},
      },
    );

export default buildSerializerConfig;
