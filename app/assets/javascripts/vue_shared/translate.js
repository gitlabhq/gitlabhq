import { __, n__, s__, sprintf } from '~/locale';

export default (Vue) => {
  Vue.mixin({
    methods: {
      /**
        Translates `text`

        @param text The text to be translated
        @returns {String} The translated text
      */
      __,
      /**
        Translate the text with a number
        if the number is more than 1 it will use the `pluralText` translation.
        This method allows for contexts, see below re. contexts

        @param text Singular text to translate (eg. '%d day')
        @param pluralText Plural text to translate (eg. '%d days')
        @param count Number to decide which translation to use (eg. 2)
        @returns {String} Translated text with the number replaced (eg. '2 days')
      */
      n__,
      /**
        Translate context based text
        Either pass in the context translation like `Context|Text to translate`
        or allow for dynamic text by doing passing in the context first & then the text to translate

        @param keyOrContext Can be either the key to translate including the context
                            (eg. 'Context|Text') or just the context for the translation
                            (eg. 'Context')
        @param key Is the dynamic variable you want to be translated
        @returns {String} Translated context based text
      */
      s__,
      sprintf,
    },
  });
};
