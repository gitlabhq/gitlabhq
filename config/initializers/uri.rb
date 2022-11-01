# frozen_string_literal: true

URI.singleton_class.prepend(Gitlab::Patch::Uri::ClassMethods)
